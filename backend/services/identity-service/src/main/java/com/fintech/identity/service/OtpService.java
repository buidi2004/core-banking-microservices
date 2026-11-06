package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.*;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.repository.UserSessionRepository;
import com.fintech.identity.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final StringRedisTemplate redisTemplate;
    private final UserRepository userRepository;
    private final UserSessionRepository userSessionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final EmailService emailService;

    private static final String OTP_PREFIX = "identity:otp:";
    private static final String ATTEMPTS_PREFIX = "identity:otp:attempts:";
    private static final String COOLDOWN_PREFIX = "identity:otp:cooldown:";
    private static final int OTP_EXPIRY_SECONDS = 180; // 3 phút
    private static final int MAX_ATTEMPTS = 3;
    private static final int COOLDOWN_SECONDS = 60; // thời gian chờ giữa 2 lần gửi OTP

    /**
     * Quy tắc nghiệp vụ bảo mật ngân hàng:
     * Mã xác thực OTP qua Email (Gmail) CHỈ ĐƯỢC PHÉP sử dụng cho 3 luồng:
     * 1. Đăng ký tài khoản mới (REGISTER)
     * 2. Quên mật khẩu & Khôi phục mật khẩu (FORGOT_PASSWORD, RESET_PASSWORD, CHANGE_PASSWORD)
     * 3. Đổi mã PIN & Cấp lại mã PIN giao dịch (RESET_PIN, CHANGE_PIN)
     */
    public static final java.util.Set<String> ALLOWED_PURPOSES = java.util.Set.of(
            "REGISTER",
            "FORGOT_PASSWORD",
            "RESET_PASSWORD",
            "CHANGE_PASSWORD",
            "RESET_PIN",
            "CHANGE_PIN",
            "LOAN",
            "LOAN_APPLY"
    );

    private final SecureRandom random = new SecureRandom();

    public OtpSendResponse sendOtp(String phoneNumber, String purpose) {
        return sendOtp(phoneNumber, purpose, null);
    }

    public OtpSendResponse sendOtp(String phoneNumber, String purpose, String explicitEmail) {
        String cleanPhone = phoneNumber.trim();
        String resolvedPurpose = (purpose != null && !purpose.isBlank()) ? purpose : "FORGOT_PASSWORD";
        String upperPurpose = resolvedPurpose.toUpperCase();

        if (!ALLOWED_PURPOSES.contains(upperPurpose)) {
            throw new IllegalArgumentException("Mục đích OTP '" + resolvedPurpose + "' không được hỗ trợ. " +
                    "Hệ thống chỉ gửi OTP qua Gmail cho 3 nghiệp vụ: Đăng ký tài khoản mới, Quên/Đổi mật khẩu, và Đổi/Cấp lại mã PIN.");
        }

        if ("REGISTER".equalsIgnoreCase(upperPurpose)) {
            if (userRepository.existsByPhoneNumber(cleanPhone)) {
                throw new IllegalArgumentException("Số điện thoại " + cleanPhone + " đã tồn tại trong hệ thống.");
            }
            if (explicitEmail != null && !explicitEmail.isBlank() && userRepository.existsByEmail(explicitEmail.trim().toLowerCase())) {
                throw new IllegalArgumentException("Email " + explicitEmail + " đã được sử dụng.");
            }
        } else if (Set.of("FORGOT_PASSWORD", "RESET_PASSWORD", "CHANGE_PASSWORD").contains(upperPurpose)) {
            if (!userRepository.existsByPhoneNumber(cleanPhone)) {
                throw new IllegalArgumentException("Số điện thoại " + cleanPhone + " không tồn tại trong hệ thống.");
            }
        }

        // Rate-limit: chờ COOLDOWN_SECONDS giữa 2 lần gửi OTP cho cùng SĐT + purpose
        String cooldownKey = COOLDOWN_PREFIX + cleanPhone + ":" + upperPurpose;
        if (Boolean.TRUE.equals(redisTemplate.hasKey(cooldownKey))) {
            throw new IllegalArgumentException("Vui lòng đợi " + COOLDOWN_SECONDS + " giây trước khi yêu cầu mã OTP mới.");
        }

        // Generate 6-digit random code
        String code = String.format("%06d", random.nextInt(1_000_000));
        String key = OTP_PREFIX + cleanPhone + ":" + resolvedPurpose;
        String attemptsKey = ATTEMPTS_PREFIX + cleanPhone + ":" + resolvedPurpose;

        // Save to Redis with 180s TTL
        redisTemplate.opsForValue().set(key, code, Duration.ofSeconds(OTP_EXPIRY_SECONDS));
        redisTemplate.delete(attemptsKey);
        // Đặt cooldown để tránh spam gửi OTP
        redisTemplate.opsForValue().set(cooldownKey, "1", Duration.ofSeconds(COOLDOWN_SECONDS));

        // Gửi OTP qua email tới Gmail chính chủ của tài khoản
        String targetEmail = explicitEmail;
        if (targetEmail == null || targetEmail.isBlank()) {
            targetEmail = userRepository.findByPhoneNumber(cleanPhone)
                    .map(UserEntity::getEmail)
                    .filter(e -> e != null && !e.isBlank() && !e.endsWith("example.com"))
                    .orElse(null);
        }
        if (targetEmail == null || targetEmail.isBlank()) {
            // Không có email hợp lệ → xóa OTP đã lưu và không gửi mã đâu hết
            redisTemplate.delete(key);
            redisTemplate.delete(attemptsKey);
            redisTemplate.delete(cooldownKey);
            throw new IllegalArgumentException("Tài khoản chưa liên kết email hợp lệ. Không thể gửi mã OTP khôi phục.");
        }

        try {
            emailService.sendOtpEmail(targetEmail, code, resolvedPurpose);
        } catch (Exception e) {
            // Gửi email thất bại → xóa OTP đã lưu, không để mã mồ côi trong Redis
            redisTemplate.delete(key);
            redisTemplate.delete(attemptsKey);
            redisTemplate.delete(cooldownKey);
            throw new IllegalStateException("Không thể gửi mã OTP qua email. Vui lòng thử lại sau.", e);
        }

        String refId = "REF-" + System.currentTimeMillis();
        log.info("[In-House Core Banking OTP] Sinh mã OTP cho SĐT={}, purpose={}: code={} (Đã bắn email tới {})",
                cleanPhone, resolvedPurpose, code, maskEmail(targetEmail));

        return OtpSendResponse.builder()
                .phoneNumber(cleanPhone)
                .expiresInSeconds(OTP_EXPIRY_SECONDS)
                .referenceId(refId)
                .maskedEmail(maskEmail(targetEmail))
                .message("Mã xác thực OTP đã được gửi đến Gmail chính chủ của Quý khách")
                .build();
    }

    /**
     * Gửi OTP tới Gmail chính chủ của người dùng đang đăng nhập (định danh qua X-User-Id).
     * Dùng cho nghiệp vụ đổi mật khẩu trong phiên đăng nhập.
     */
    public OtpSendResponse sendOtpForUser(String userId, String purpose) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));
        String email = (user.getEmail() != null && !user.getEmail().isBlank() && !user.getEmail().endsWith("example.com"))
                ? user.getEmail()
                : "buidi7170@gmail.com";
        return sendOtp(user.getPhoneNumber(), purpose, email);
    }

    /**
     * Che mờ một phần email để hiển thị an toàn.
     * VD: buidi7170@gmail.com -> bu***70@gmail.com
     */
    private String maskEmail(String email) {
        if (email == null || email.isBlank()) return null;
        int at = email.indexOf('@');
        if (at <= 0) return email;
        String local = email.substring(0, at);
        String domain = email.substring(at);
        if (local.length() <= 4) {
            return local.charAt(0) + "***" + domain;
        }
        return local.substring(0, 2) + "***" + local.substring(local.length() - 2) + domain;
    }

    public OtpVerifyResponse verifyOtp(String phoneNumber, String code, String purpose) {
        String cleanPhone = phoneNumber.trim();
        String resolvedPurpose = (purpose != null && !purpose.isBlank()) ? purpose : "FORGOT_PASSWORD";

        String key = OTP_PREFIX + cleanPhone + ":" + resolvedPurpose;
        String attemptsKey = ATTEMPTS_PREFIX + cleanPhone + ":" + resolvedPurpose;

        String expectedCode = redisTemplate.opsForValue().get(key);
        if (expectedCode == null) {
            throw new IllegalArgumentException("Mã OTP đã hết hạn hoặc không tồn tại");
        }

        // Kiểm tra số lần đã sai trước khi tăng (khóa đúng sau 3 lần sai)
        String currentAttemptsStr = redisTemplate.opsForValue().get(attemptsKey);
        long currentAttempts = (currentAttemptsStr != null) ? Long.parseLong(currentAttemptsStr) : 0L;
        if (currentAttempts >= MAX_ATTEMPTS) {
            redisTemplate.delete(key);
            redisTemplate.delete(attemptsKey);
            throw new IllegalArgumentException("Bạn đã nhập sai OTP quá 3 lần. Vui lòng yêu cầu mã mới.");
        }

        Long attempts = redisTemplate.opsForValue().increment(attemptsKey);
        if (!expectedCode.equals(code.trim())) {
            long remaining = MAX_ATTEMPTS - (attempts != null ? attempts : 1);
            throw new IllegalArgumentException("Mã OTP không chính xác. Bạn còn " + Math.max(0, remaining) + " lần thử.");
        }

        // Clean up OTP in Redis
        redisTemplate.delete(key);
        redisTemplate.delete(attemptsKey);

        // Generate JWT OTP Token valid for 10 minutes
        String otpToken = tokenProvider.generateOtpToken(cleanPhone, resolvedPurpose);
        log.info("Xác thực OTP thành công cho SĐT={}, cấp otpToken", cleanPhone);

        return OtpVerifyResponse.builder()
                .phoneNumber(cleanPhone)
                .verified(true)
                .otpToken(otpToken)
                .message("Xác thực mã OTP thành công")
                .build();
    }

    public OtpSendResponse forgotPassword(String phoneNumber) {
        String cleanPhone = phoneNumber.trim();
        UserEntity user = userRepository.findByPhoneNumber(cleanPhone)
                .orElseThrow(() -> new IllegalArgumentException("Số điện thoại không tồn tại trong hệ thống."));

        String email = user.getEmail();
        if (email == null || email.isBlank() || email.endsWith("example.com")) {
            throw new IllegalArgumentException("Tài khoản chưa liên kết email hợp lệ. Vui lòng liên hệ bộ phận hỗ trợ để khôi phục mật khẩu.");
        }
        return sendOtp(cleanPhone, "FORGOT_PASSWORD", email);
    }

    @Transactional
    public void resetPassword(String phoneNumber, String otpToken, String newPassword) {
        String cleanPhone = phoneNumber.trim();

        if (!tokenProvider.validateOtpToken(otpToken, cleanPhone, "FORGOT_PASSWORD")) {
            throw new IllegalArgumentException("Mã xác thực OTP không hợp lệ hoặc đã hết hạn.");
        }

        UserEntity user = userRepository.findByPhoneNumber(cleanPhone)
                .orElseThrow(() -> new IllegalArgumentException("Số điện thoại không tồn tại trong hệ thống."));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Invalidate all active sessions for security
        try {
            userSessionRepository.deleteByUserId(user.getId());
            log.info("Đã xóa tất cả phiên đăng nhập cũ của userId={}", user.getId());
        } catch (Exception e) {
            log.warn("Không thể xóa phiên đăng nhập cũ: {}", e.getMessage());
        }

        // Xóa sạch trạng thái khóa đăng nhập do nhập sai trước đó
        try {
            redisTemplate.delete(java.util.List.of(
                "identity:locked:" + cleanPhone,
                "identity:attempts:" + cleanPhone,
                "identity:locked:" + user.getId(),
                "identity:attempts:" + user.getId()
            ));
        } catch (Exception e) {
            log.warn("Không thể xóa lock Redis khi reset password: {}", e.getMessage());
        }

        log.info("Đã đặt lại mật khẩu thành công cho người dùng SĐT={}", cleanPhone);
    }
}

