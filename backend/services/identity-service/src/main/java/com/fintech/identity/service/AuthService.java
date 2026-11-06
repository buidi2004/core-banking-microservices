package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.domain.entity.UserProfileEntity;
import com.fintech.identity.domain.entity.UserSessionEntity;
import com.fintech.identity.dto.AuthResponse;
import com.fintech.identity.dto.ChangePasswordRequest;
import com.fintech.identity.dto.LoginRequest;
import com.fintech.identity.dto.RefreshTokenRequest;
import com.fintech.identity.dto.RegisterRequest;
import com.fintech.identity.messaging.IdentityEventPublisher;
import com.fintech.identity.repository.UserProfileRepository;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.repository.UserSessionRepository;
import com.fintech.identity.security.JwtTokenProvider;
import com.fintech.wallet.domain.event.UserRegisteredEvent;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserSessionRepository userSessionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final IdentityEventPublisher eventPublisher;
    private final StringRedisTemplate redisTemplate;

    private static final String LOCK_PREFIX = "identity:locked:";
    private static final String ATTEMPTS_PREFIX = "identity:attempts:";
    private static final int MAX_ATTEMPTS = 5;

    public static String normalizePhoneNumber(String phone) {
        if (phone == null || phone.isBlank()) {
            return "";
        }
        String clean = phone.replaceAll("[\\s\\-\\.\\(\\)]", "").trim();
        if (clean.startsWith("+84")) {
            return "0" + clean.substring(3);
        }
        if (clean.startsWith("84") && clean.length() == 11) {
            return "0" + clean.substring(2);
        }
        return clean;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String rawPhone = request.getPhoneNumber();
        String phone = normalizePhoneNumber(rawPhone);
        if (userRepository.existsByPhoneNumber(phone) || (rawPhone != null && !rawPhone.equals(phone) && userRepository.existsByPhoneNumber(rawPhone.trim()))) {
            throw new IllegalArgumentException("Số điện thoại " + phone + " đã tồn tại trong hệ thống.");
        }

        // Email (Gmail) là bắt buộc: dùng để gửi OTP xác thực & bảo mật các nghiệp vụ sau này.
        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : null;
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Địa chỉ Gmail là bắt buộc để xác thực tài khoản.");
        }
        if (!email.matches("^[A-Za-z0-9+_.\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$")) {
            throw new IllegalArgumentException("Địa chỉ email không hợp lệ.");
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email " + email + " đã được sử dụng.");
        }

        String userId = UUID.randomUUID().toString();
        String passwordHash = passwordEncoder.encode(request.getPassword());

        // 1. Lưu User vào ewallet_identity_db
        UserEntity user = UserEntity.builder()
                .id(userId)
                .phoneNumber(phone)
                .fullName(request.getFullName().trim())
                .email(email)
                .passwordHash(passwordHash)
                .role("ROLE_USER")
                .status("ACTIVE")
                .kycTier("UNVERIFIED")
                .build();
        userRepository.save(user);

        // 2. Tạo UserProfile mặc định
        UserProfileEntity profile = UserProfileEntity.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .build();
        userProfileRepository.save(profile);

        log.info("Đã tạo người dùng mới trong ewallet_identity_db: userId={}, phone={}", userId, phone);

        // 3. Xuất bản sự kiện UserRegisteredEvent lên RabbitMQ (Event-Driven Onboarding)
        UserRegisteredEvent registeredEvent = UserRegisteredEvent.of(
                userId,
                phone,
                request.getFullName().trim(),
                0, // Tier 0 = UNVERIFIED
                "VN"
        );
        eventPublisher.publishUserRegistered(registeredEvent);

        // 4. Sinh JWT Tokens
        String accessToken = tokenProvider.generateAccessToken(
                userId,
                phone,
                user.getRole(),
                user.getKycTier(),
                user.getBranchId(),
                user.getFullName()
        );
        String refreshToken = tokenProvider.generateRefreshToken(userId);

        return AuthResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(tokenProvider.getAccessTokenExpirationSeconds())
                .userId(userId)
                .username(user.getUsername() != null ? user.getUsername() : phone)
                .phoneNumber(phone)
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .roles(java.util.List.of(user.getRole()))
                .branchId(user.getBranchId())
                .kycTier(user.getKycTier())
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest request, String ipAddress, String userAgent) {
        String rawIdentifier = request.getIdentifier();
        if (rawIdentifier == null || rawIdentifier.isBlank()) {
            throw new IllegalArgumentException("Username hoặc số điện thoại là bắt buộc.");
        }
        String identifier = rawIdentifier.trim();
        String normalizedPhone = normalizePhoneNumber(identifier);

        String lockKey = LOCK_PREFIX + identifier;
        String normLockKey = LOCK_PREFIX + normalizedPhone;

        // Kiểm tra xem tài khoản có đang bị khóa đăng nhập tạm thời trong Redis không (bảo vệ resilient)
        try {
            if (Boolean.TRUE.equals(redisTemplate.hasKey(lockKey)) ||
                    (!normLockKey.equals(lockKey) && Boolean.TRUE.equals(redisTemplate.hasKey(normLockKey)))) {
                throw new IllegalStateException("Tài khoản đang bị tạm khóa 30 phút do nhập sai mật khẩu quá 5 lần.");
            }
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Không thể kiểm tra Redis lock cho {}: {}", identifier, e.getMessage());
        }

        // Tìm User: đa hình thức định danh (SĐT chuẩn, SĐT gốc, email, username)
        UserEntity user = userRepository.findByIdentifier(identifier).orElse(null);
        if (user == null && !normalizedPhone.equals(identifier)) {
            user = userRepository.findByIdentifier(normalizedPhone).orElse(null);
        }
        if (user == null && !identifier.toLowerCase().equals(identifier)) {
            user = userRepository.findByIdentifier(identifier.toLowerCase()).orElse(null);
        }

        boolean passwordValid = false;
        if (user != null && request.getPassword() != null && user.getPasswordHash() != null) {
            String rawPassword = request.getPassword();
            String trimmedPassword = rawPassword.trim();
            String userHash = user.getPasswordHash();

            // 1. So khớp mật khẩu chính xác nguyên bản
            passwordValid = passwordEncoder.matches(rawPassword, userHash);

            // 2. Thử so khớp khi cắt bỏ khoảng trắng đầu/cuối (xử lý bàn phím ảo/autofill mobile tự thêm space)
            if (!passwordValid && !rawPassword.equals(trimmedPassword)) {
                passwordValid = passwordEncoder.matches(trimmedPassword, userHash);
            }

        }

        if (user == null || !passwordValid) {
            long remaining = MAX_ATTEMPTS - 1;
            String attemptTarget = (user != null && user.getPhoneNumber() != null) ? user.getPhoneNumber() : normalizedPhone;
            String attemptsKey = ATTEMPTS_PREFIX + attemptTarget;
            String lockTargetKey = LOCK_PREFIX + attemptTarget;

            try {
                Long attempts = redisTemplate.opsForValue().increment(attemptsKey);
                redisTemplate.expire(attemptsKey, Duration.ofMinutes(15));
                if (attempts != null && attempts >= MAX_ATTEMPTS) {
                    redisTemplate.opsForValue().set(lockTargetKey, "LOCKED", Duration.ofMinutes(30));
                    redisTemplate.delete(attemptsKey);
                    throw new IllegalStateException("Tài khoản đã bị tạm khóa 30 phút do đăng nhập sai 5 lần.");
                }
                if (attempts != null) {
                    remaining = Math.max(0, MAX_ATTEMPTS - attempts);
                }
            } catch (IllegalStateException e) {
                throw e;
            } catch (Exception e) {
                log.warn("Không thể cập nhật Redis login attempts cho {}: {}", attemptTarget, e.getMessage());
            }
            throw new IllegalArgumentException("Thông tin đăng nhập hoặc mật khẩu không chính xác. Còn " + remaining + " lần thử.");
        }

        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new IllegalStateException("Tài khoản của bạn đã bị khóa hoặc ngừng hoạt động.");
        }

        // Đăng nhập thành công -> Xóa bộ đếm sai & khóa tạm thời (đồng bộ mọi định danh)
        try {
            java.util.List<String> keysToDelete = new java.util.ArrayList<>();
            keysToDelete.add(ATTEMPTS_PREFIX + identifier);
            keysToDelete.add(LOCK_PREFIX + identifier);
            if (user.getPhoneNumber() != null) {
                keysToDelete.add(ATTEMPTS_PREFIX + user.getPhoneNumber());
                keysToDelete.add(LOCK_PREFIX + user.getPhoneNumber());
            }
            if (user.getUsername() != null) {
                keysToDelete.add(ATTEMPTS_PREFIX + user.getUsername());
                keysToDelete.add(LOCK_PREFIX + user.getUsername());
            }
            keysToDelete.add(ATTEMPTS_PREFIX + user.getId());
            keysToDelete.add(LOCK_PREFIX + user.getId());
            redisTemplate.delete(keysToDelete);
        } catch (Exception e) {
            log.warn("Không thể dọn dẹp Redis attempt keys cho {}: {}", user.getPhoneNumber(), e.getMessage());
        }

        // Sinh JWT Access Token & Refresh Token (chứa roles, branch_id, full_name)
        String accessToken = tokenProvider.generateAccessToken(
                user.getId(),
                user.getPhoneNumber(),
                user.getRole(),
                user.getKycTier(),
                user.getBranchId(),
                user.getFullName()
        );
        String refreshToken = tokenProvider.generateRefreshToken(user.getId());

        // Quản lý phiên làm việc thiết bị (User Session)
        if (request.getDeviceId() != null && !request.getDeviceId().isBlank()) {
            saveUserSession(user.getId(), request.getDeviceId(), request.getDeviceName(), request.getDeviceOs(),
                    ipAddress, userAgent, refreshToken);
        }

        return AuthResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(tokenProvider.getAccessTokenExpirationSeconds())
                .userId(user.getId())
                .username(user.getUsername() != null ? user.getUsername() : identifier)
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .roles(java.util.List.of(user.getRole()))
                .branchId(user.getBranchId())
                .kycTier(user.getKycTier())
                .build();
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();
        Claims claims = tokenProvider.parseAndValidateToken(refreshToken);

        String type = claims.get("type", String.class);
        if (!JwtTokenProvider.TOKEN_TYPE_REFRESH.equals(type)) {
            throw new IllegalArgumentException("Token không phải loại REFRESH token.");
        }

        String userId = claims.getSubject();
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng."));

        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())) {
            throw new IllegalStateException("Tài khoản đã bị vô hiệu hóa.");
        }

        // Kiểm tra session tương ứng nếu có deviceId
        if (request.getDeviceId() != null && !request.getDeviceId().isBlank()) {
            userSessionRepository.findByUserIdAndDeviceId(userId, request.getDeviceId())
                    .ifPresent(session -> {
                        if (Boolean.TRUE.equals(session.getIsRevoked())) {
                            throw new IllegalStateException("Phiên đăng nhập trên thiết bị này đã bị thu hồi.");
                        }
                    });
        }

        String newAccessToken = tokenProvider.generateAccessToken(
                user.getId(),
                user.getPhoneNumber(),
                user.getRole(),
                user.getKycTier(),
                user.getBranchId(),
                user.getFullName()
        );

        return AuthResponse.builder()
                .token(newAccessToken)
                .refreshToken(refreshToken) // Giữ nguyên refresh token hiện tại
                .tokenType("Bearer")
                .expiresIn(tokenProvider.getAccessTokenExpirationSeconds())
                .userId(user.getId())
                .username(user.getUsername() != null ? user.getUsername() : user.getPhoneNumber())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .roles(java.util.List.of(user.getRole()))
                .branchId(user.getBranchId())
                .kycTier(user.getKycTier())
                .build();
    }

    @Transactional
    public void changePassword(String bearerToken, String headerUserId, ChangePasswordRequest request) {
        String userId = headerUserId;
        if (userId == null || userId.isBlank()) {
            if (bearerToken != null && !bearerToken.isBlank()) {
                String token = bearerToken.startsWith("Bearer ") ? bearerToken.substring(7) : bearerToken;
                Claims claims = tokenProvider.parseAndValidateToken(token);
                userId = claims.getSubject();
            }
        }
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("Không xác định được danh tính người dùng");
        }

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Mật khẩu hiện tại không chính xác");
        }

        // Đối soát mã OTP Gmail (CHANGE_PASSWORD) trước khi cập nhật mật khẩu mới.
        String otp = request.getOtp();
        if (otp == null || otp.isBlank()) {
            throw new IllegalArgumentException("Mã OTP xác thực là bắt buộc");
        }
        if (!tokenProvider.validateOtpToken(otp, user.getPhoneNumber(), "CHANGE_PASSWORD")) {
            throw new IllegalArgumentException("Mã OTP xác thực không hợp lệ hoặc đã hết hạn");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Blacklist token hiện tại & thu hồi sessions
        if (bearerToken != null && !bearerToken.isBlank()) {
            String token = bearerToken.startsWith("Bearer ") ? bearerToken.substring(7) : bearerToken;
            tokenProvider.blacklistToken(token);
        }
        userSessionRepository.findByUserIdAndIsRevokedFalse(userId).forEach(s -> {
            s.setIsRevoked(true);
            userSessionRepository.save(s);
        });

        // Xóa sạch trạng thái khóa đăng nhập do nhập sai trước đó
        try {
            redisTemplate.delete(java.util.List.of(
                LOCK_PREFIX + user.getPhoneNumber(),
                ATTEMPTS_PREFIX + user.getPhoneNumber(),
                LOCK_PREFIX + user.getId(),
                ATTEMPTS_PREFIX + user.getId()
            ));
        } catch (Exception e) {
            log.warn("Không thể xóa lock Redis khi change password: {}", e.getMessage());
        }

        log.info("Đổi mật khẩu thành công cho userId={}, phone={}", user.getId(), user.getPhoneNumber());
    }

    @Transactional
    public void logout(String bearerToken, String userId, String deviceId) {
        if (bearerToken != null && !bearerToken.isBlank()) {
            String token = bearerToken.startsWith("Bearer ") ? bearerToken.substring(7) : bearerToken;
            tokenProvider.blacklistToken(token);
        }

        if (userId != null && deviceId != null) {
            userSessionRepository.findByUserIdAndDeviceId(userId, deviceId)
                    .ifPresent(session -> {
                        session.setIsRevoked(true);
                        userSessionRepository.save(session);
                    });
        }
    }

    @Transactional
    public Map<String, Object> emergencyLock(String bearerToken, String userId, String reason) {
        if (bearerToken != null && !bearerToken.isBlank()) {
            String token = bearerToken.startsWith("Bearer ") ? bearerToken.substring(7) : bearerToken;
            tokenProvider.blacklistToken(token);
        }

        if (userId != null && !userId.isBlank()) {
            List<UserSessionEntity> sessions = userSessionRepository.findByUserIdAndIsRevokedFalse(userId);
            for (UserSessionEntity s : sessions) {
                s.setIsRevoked(true);
            }
            userSessionRepository.saveAll(sessions);

            userRepository.findById(userId).ifPresent(u -> {
                u.setStatus("BLOCKED");
                userRepository.save(u);
            });
        }

        log.warn("EMERGENCY LOCK: Tài khoản người dùng {} đã bị KHÓA KHẨN CẤP. Lý do: {}", userId, reason);

        return Map.of(
                "status", "BLOCKED",
                "lockedAt", Instant.now().toString(),
                "reason", (reason != null && !reason.isBlank()) ? reason : "Yêu cầu khóa khẩn cấp phòng chống gian lận",
                "message", "Đã kích hoạt chế độ khóa khẩn cấp toàn diện. Tài khoản và mọi phiên đăng nhập đã bị phong tỏa."
        );
    }

    private void saveUserSession(String userId, String deviceId, String deviceName, String deviceOs,
                                 String ipAddress, String userAgent, String refreshToken) {
        String tokenHash = sha256(refreshToken);
        Instant expiry = Instant.now().plus(Duration.ofDays(7));

        UserSessionEntity session = userSessionRepository.findByUserIdAndDeviceId(userId, deviceId)
                .orElseGet(() -> UserSessionEntity.builder()
                        .id(UUID.randomUUID().toString())
                        .userId(userId)
                        .deviceId(deviceId)
                        .build());

        session.setDeviceName(deviceName);
        session.setDeviceOs(deviceOs);
        session.setIpAddress(ipAddress);
        session.setUserAgent(userAgent);
        session.setRefreshTokenHash(tokenHash);
        session.setExpiresAt(expiry);
        session.setIsRevoked(false);
        session.setLastAccessedAt(Instant.now());

        userSessionRepository.save(session);
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            return String.valueOf(input.hashCode());
        }
    }
}
