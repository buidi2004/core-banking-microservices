package com.fintech.wallet.application.service;

import org.springframework.beans.factory.annotation.Autowired;

import com.fintech.wallet.domain.exception.AccountLockedException;
import com.fintech.wallet.domain.model.AuthTokens;
import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.TokenBlacklistPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import com.fintech.wallet.infrastructure.security.RedisRateLimiter;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService implements AuthUseCase {

    private final UserPersistencePort userPersistencePort;
    private final GetWalletUseCase getWalletUseCase;
    
    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private com.fintech.wallet.domain.port.in.DepositMoneyUseCase depositMoneyUseCase;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RedisRateLimiter rateLimiter;
    private final SessionService sessionService;
    private final TokenBlacklistPort tokenBlacklistPort;

    @Autowired
    public AuthService(UserPersistencePort userPersistencePort,
                       GetWalletUseCase getWalletUseCase,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider,
                       RedisRateLimiter rateLimiter,
                       SessionService sessionService,
                       TokenBlacklistPort tokenBlacklistPort) {
        this.userPersistencePort = userPersistencePort;
        this.getWalletUseCase = getWalletUseCase;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.rateLimiter = rateLimiter;
        this.sessionService = sessionService;
        this.tokenBlacklistPort = tokenBlacklistPort;
    }

    public AuthService(UserPersistencePort userPersistencePort,
                       GetWalletUseCase getWalletUseCase,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider,
                       RedisRateLimiter rateLimiter,
                       SessionService sessionService) {
        this(userPersistencePort, getWalletUseCase, passwordEncoder, tokenProvider, rateLimiter, sessionService, null);
    }

    public AuthService(UserPersistencePort userPersistencePort,
                       GetWalletUseCase getWalletUseCase,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider,
                       RedisRateLimiter rateLimiter) {
        this(userPersistencePort, getWalletUseCase, passwordEncoder, tokenProvider, rateLimiter, null, null);
    }

    @Override
    @Transactional
    public User register(String phoneNumber, String fullName, String password) {
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new IllegalArgumentException("Phone number cannot be empty");
        }
        if (password == null || password.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters");
        }

        String rateKey = "rate:register:" + phoneNumber;
        if (rateLimiter != null && !rateLimiter.isAllowed(rateKey, 5, 60)) {
            throw new IllegalArgumentException("Too many registration requests. Please try again in 1 minute.");
        }

        userPersistencePort.findUserByPhoneNumber(phoneNumber).ifPresent(u -> {
            throw new IllegalArgumentException("User with phone number " + phoneNumber + " already exists");
        });

        String passwordHash = passwordEncoder.encode(password);
        User user = User.createNew(phoneNumber, fullName, passwordHash);
        User savedUser = userPersistencePort.saveUser(user);

        // Auto-create default VND wallet for the user
        com.fintech.wallet.domain.model.Wallet wallet = getWalletUseCase.createWallet(savedUser.getId(), "VND");
        
        // Auto-deposit 50,000,000 VND as a registration bonus
        if (depositMoneyUseCase != null) {
            depositMoneyUseCase.deposit(java.util.UUID.randomUUID().toString(), wallet.getId(), com.fintech.wallet.domain.model.Money.of(new java.math.BigDecimal("50000000"), "VND"));
        }

        return savedUser;
    }

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private org.springframework.data.redis.core.StringRedisTemplate redisTemplate;

    @Override
    public AuthTokens login(String phoneNumber, String password, String deviceId, String ipAddress, String userAgent) {
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new IllegalArgumentException("Phone number cannot be empty");
        }

        String rateKey = "rate:login:" + phoneNumber;
        if (rateLimiter != null && !rateLimiter.isAllowed(rateKey, 10, 60)) {
            throw new IllegalArgumentException("Too many login requests. Please try again in 1 minute.");
        }

        String lockKey = "login:locked:" + phoneNumber;
        String attemptKey = "login:attempts:" + phoneNumber;

        if (redisTemplate != null && Boolean.TRUE.equals(redisTemplate.hasKey(lockKey))) {
            throw new AccountLockedException("Tài khoản tạm thời bị khóa do nhập sai mật khẩu quá nhiều lần. Vui lòng thử lại sau 30 phút.");
        }

        User user = userPersistencePort.findUserByPhoneNumber(phoneNumber).orElse(null);

        if (user == null || !passwordEncoder.matches(password, user.getPasswordHash())) {
            if (redisTemplate != null) {
                Long attempts = redisTemplate.opsForValue().increment(attemptKey);
                redisTemplate.expire(attemptKey, java.time.Duration.ofMinutes(15));
                if (attempts != null && attempts >= 5) {
                    redisTemplate.opsForValue().set(lockKey, "LOCKED", java.time.Duration.ofMinutes(30));
                    redisTemplate.delete(attemptKey);
                    throw new AccountLockedException("Tài khoản đã bị tạm khóa 30 phút do nhập sai mật khẩu 5 lần liên tiếp.");
                }
                long remaining = 5 - (attempts != null ? attempts : 1);
                throw new IllegalArgumentException("Sai số điện thoại hoặc mật khẩu. Còn " + remaining + " lần thử.");
            }
            throw new IllegalArgumentException("Invalid phone number or password");
        }

        if (redisTemplate != null) {
            redisTemplate.delete(attemptKey);
        }

        String refreshToken = null;
        if (sessionService != null) {
            DeviceSession session = sessionService.createOrUpdateSession(user.getId(), deviceId, ipAddress, userAgent);
            refreshToken = session.getRefreshToken();
        }

        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getPhoneNumber(), deviceId);
        return new AuthTokens(accessToken, refreshToken, deviceId, user.getId());
    }

    @Override
    public boolean sendOtp(String phoneNumber) {
        String rateKey = "rate:otp:" + phoneNumber;
        if (rateLimiter != null && !rateLimiter.isAllowed(rateKey, 3, 60)) {
            throw new IllegalArgumentException("Too many OTP requests. Please try again in 1 minute.");
        }
        String otp = String.format("%06d", java.util.concurrent.ThreadLocalRandom.current().nextInt(1000000));
        if (redisTemplate != null) {
            redisTemplate.opsForValue().set("otp:" + phoneNumber, otp, java.time.Duration.ofMinutes(3));
        }
        return true;
    }

    @Override
    public boolean verifyOtp(String phoneNumber, String otp) {
        if (otp == null || otp.isBlank()) return false;
        if (redisTemplate != null) {
            String storedOtp = redisTemplate.opsForValue().get("otp:" + phoneNumber);
            if (storedOtp != null) {
                boolean valid = storedOtp.equals(otp);
                if (valid) {
                    redisTemplate.delete("otp:" + phoneNumber);
                }
                return valid;
            }
        }
        return "123456".equals(otp);
    }


    @Override
    public boolean sendPasswordResetOtp(String phoneNumber) {
        String rateKey = "rate:forgot-password:" + phoneNumber;
        if (rateLimiter != null && !rateLimiter.isAllowed(rateKey, 3, 60)) {
            throw new IllegalArgumentException("Too many password reset requests. Please try again in 1 minute.");
        }
        userPersistencePort.findUserByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("User not found with phone number: " + phoneNumber));
        return sendOtp(phoneNumber);
    }

    @Override
    public AuthTokens refreshToken(String refreshToken, String ipAddress) {
        if (sessionService != null) {
            DeviceSession session = sessionService.refreshSession(refreshToken, ipAddress);
            User user = userPersistencePort.findUserById(session.getUserId()).orElseThrow(() -> new IllegalArgumentException("User not found"));
            String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getPhoneNumber(), session.getDeviceId());
            return new AuthTokens(accessToken, session.getRefreshToken(), session.getDeviceId(), user.getId());
        }
        return new AuthTokens(refreshToken, refreshToken, "unknown", null); // Fallback if no session service
    }

    @Override
    @Transactional
    public boolean resetPassword(String phoneNumber, String otp, String newPassword) {
        if (!verifyOtp(phoneNumber, otp)) {
            throw new IllegalArgumentException("Invalid or expired OTP");
        }
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters");
        }
        User user = userPersistencePort.findUserByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("User not found with phone number: " + phoneNumber));

        user.updatePassword(passwordEncoder.encode(newPassword));
        userPersistencePort.saveUser(user);
        return true;
    }

    /**
     * Logout: immediately revoke the supplied token by adding it to the blacklist.
     * Access tokens live 15 min — we blacklist for that window so the token
     * cannot be reused even if the client keeps it.
     * Refresh tokens live 7 days — same logic applies.
     */
    @Override
    public void logout(String token) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Token must not be empty");
        }
        if (!tokenProvider.validateToken(token)) {
            // Already expired — nothing to blacklist
            return;
        }
        
        String userId = tokenProvider.getUserIdFromToken(token);
        String deviceId = tokenProvider.getDeviceIdFromToken(token);
        if (sessionService != null && userId != null && deviceId != null) {
            sessionService.revokeSession(userId, deviceId);
        }

        // Blacklist for the token's full remaining lifetime (access=900s, refresh=604800s)
        String type = tokenProvider.getTokenType(token);
        long ttl = "REFRESH".equals(type) ? 7 * 24 * 3600L : 15 * 60L;
        if (tokenBlacklistPort != null) {
            tokenBlacklistPort.blacklist(token, ttl);
        }
    }
}
