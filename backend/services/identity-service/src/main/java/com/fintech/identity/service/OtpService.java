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
    private static final int OTP_EXPIRY_SECONDS = 180; // 3 phút
    private static final int MAX_ATTEMPTS = 3;

    private final SecureRandom random = new SecureRandom();

    public OtpSendResponse sendOtp(String phoneNumber, String purpose) {
        return sendOtp(phoneNumber, purpose, null);
    }

    public OtpSendResponse sendOtp(String phoneNumber, String purpose, String explicitEmail) {
        String cleanPhone = phoneNumber.trim();
        String resolvedPurpose = (purpose != null && !purpose.isBlank()) ? purpose : "FORGOT_PASSWORD";

        // Generate 6-digit random code
        String code = String.format("%06d", random.nextInt(1_000_000));
        String key = OTP_PREFIX + cleanPhone + ":" + resolvedPurpose;
        String attemptsKey = ATTEMPTS_PREFIX + cleanPhone + ":" + resolvedPurpose;

        // Save to Redis with 180s TTL
        redisTemplate.opsForValue().set(key, code, Duration.ofSeconds(OTP_EXPIRY_SECONDS));
        redisTemplate.delete(attemptsKey);

        // Gửi OTP qua Email (Gmail chính chủ của tài khoản). KHÔNG dùng email dự phòng cứng.
        String targetEmail = explicitEmail;
        if (targetEmail == null || targetEmail.isBlank()) {
            targetEmail = userRepository.findByPhoneNumber(cleanPhone)
                    .map(UserEntity::getEmail)
                    .filter(e -> e != null && !e.isBlank())
                    .orElse(null);
        }

        if (targetEmail != null && !targetEmail.isBlank()) {
            emailService.sendOtpEmail(targetEmail, code, resolvedPurpose);
        } else {
            log.warn("[In-House Core Banking OTP] Không tìm thấy Gmail của người dùng SĐT={} để gửi OTP (purpose={})",
                    cleanPhone, resolvedPurpose);
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
        if (user.getEmail() == null || user.getEmail().isBlank()) {
            throw new IllegalStateException("Tài khoản chưa liên kết Gmail. Vui lòng cập nhật email trước khi đổi mật khẩu.");
        }
        return sendOtp(user.getPhoneNumber(), purpose, user.getEmail());
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

        Long attempts = redisTemplate.opsForValue().increment(attemptsKey);
        if (attempts != null && attempts > MAX_ATTEMPTS) {
            redisTemplate.delete(key);
            redisTemplate.delete(attemptsKey);
            throw new IllegalArgumentException("Bạn đã nhập sai OTP quá 3 lần. Vui lòng yêu cầu mã mới.");
        }

        if (!expectedCode.equals(code.trim())) {
            long remaining = MAX_ATTEMPTS - (attempts != null ? attempts : 1);
            throw new IllegalArgumentException("Mã OTP không chính xác. Bạn còn " + remaining + " lần thử.");
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

        if (user.getEmail() == null || user.getEmail().isBlank()) {
            log.warn("Tài khoản SĐT={} chưa liên kết Gmail. Không thể gửi OTP khôi phục mật khẩu.", cleanPhone);
        }
        return sendOtp(cleanPhone, "FORGOT_PASSWORD", user.getEmail());
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

        log.info("Đã đặt lại mật khẩu thành công cho người dùng SĐT={}", cleanPhone);
    }
}

