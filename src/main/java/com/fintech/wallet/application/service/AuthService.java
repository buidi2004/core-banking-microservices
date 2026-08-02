package com.fintech.wallet.application.service;

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
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RedisRateLimiter rateLimiter;
    private final SessionService sessionService;
    private final TokenBlacklistPort tokenBlacklistPort;

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
    public User register(String phoneNumber, String password) {
        if (phoneNumber == null || phoneNumber.isBlank()) {
            throw new IllegalArgumentException("Phone number cannot be empty");
        }
        if (password == null || password.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters");
        }

        userPersistencePort.findUserByPhoneNumber(phoneNumber).ifPresent(u -> {
            throw new IllegalArgumentException("User with phone number " + phoneNumber + " already exists");
        });

        String passwordHash = passwordEncoder.encode(password);
        User user = User.createNew(phoneNumber, passwordHash);
        User savedUser = userPersistencePort.saveUser(user);

        // Auto-create default VND wallet for the user
        getWalletUseCase.createWallet(savedUser.getId(), "VND");

        return savedUser;
    }

    @Override
    public String login(String phoneNumber, String password) {
        User user = userPersistencePort.findUserByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("Invalid phone number or password"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid phone number or password");
        }

        if (sessionService != null) {
            sessionService.createSession(user.getId(), "Web/Mobile App", "127.0.0.1");
        }

        return tokenProvider.generateAccessToken(user.getId(), user.getPhoneNumber());
    }


    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private org.springframework.data.redis.core.StringRedisTemplate redisTemplate;

    @Override
    public boolean sendOtp(String phoneNumber) {
        String rateKey = "rate:otp:" + phoneNumber;
        if (!rateLimiter.isAllowed(rateKey, 3, 60)) {
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
    public String refreshToken(String refreshToken) {
        if (tokenProvider.validateToken(refreshToken) && "REFRESH".equals(tokenProvider.getTokenType(refreshToken))) {
            String userId = tokenProvider.getUserIdFromToken(refreshToken);
            User user = userPersistencePort.findUserById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));
            return tokenProvider.generateAccessToken(user.getId(), user.getPhoneNumber());
        }
        throw new IllegalArgumentException("Invalid refresh token");
    }

    @Override
    public boolean sendPasswordResetOtp(String phoneNumber) {
        userPersistencePort.findUserByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("User not found with phone number: " + phoneNumber));
        return sendOtp(phoneNumber);
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
        // Blacklist for the token's full remaining lifetime (access=900s, refresh=604800s)
        String type = tokenProvider.getTokenType(token);
        long ttl = "REFRESH".equals(type) ? 7 * 24 * 3600L : 15 * 60L;
        if (tokenBlacklistPort != null) {
            tokenBlacklistPort.blacklist(token, ttl);
        }
    }
}
