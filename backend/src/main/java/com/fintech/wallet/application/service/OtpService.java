package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InvalidPinException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class OtpService {

    private static final String OTP_PREFIX = "otp:trans:";
    private static final String FAIL_COUNT_PREFIX = "failed_confirm:";
    private static final String LOCK_PREFIX = "locked_user:";
    
    private static final int MAX_ATTEMPTS = 3;
    private static final long LOCK_DURATION_MINUTES = 15;
    private static final long OTP_TTL_MINUTES = 5;

    private final RedisTemplate<String, Object> redisTemplate;

    public OtpService(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public String generateAndStoreOtp(String transactionId) {
        String otp = String.format("%06d", ThreadLocalRandom.current().nextInt(1000000));
        redisTemplate.opsForValue().set(OTP_PREFIX + transactionId, otp, Duration.ofMinutes(OTP_TTL_MINUTES));
        return otp; // In real life this would be sent via SMS/Email
    }

    public void verifyOtpOrPin(String userId, String transactionId, String providedOtp, String providedPin, PinUseCaseImpl pinUseCase) {
        checkLock(userId);

        boolean isValid = false;

        if (providedOtp != null && !providedOtp.isEmpty()) {
            String storedOtp = (String) redisTemplate.opsForValue().get(OTP_PREFIX + transactionId);
            if (providedOtp.equals(storedOtp)) {
                isValid = true;
                redisTemplate.delete(OTP_PREFIX + transactionId); // Consume OTP
            }
        } else if (providedPin != null && !providedPin.isEmpty()) {
            // we will pass a callback or just use the PinUseCase directly
            isValid = pinUseCase.verifyPin(userId, providedPin);
        } else {
            throw new InvalidPinException("PIN or OTP is required");
        }

        if (!isValid) {
            handleFailedAttempt(userId);
            throw new InvalidPinException("Invalid PIN or OTP");
        } else {
            // reset failed attempts on success
            redisTemplate.delete(FAIL_COUNT_PREFIX + userId);
        }
    }

    private void checkLock(String userId) {
        if (Boolean.TRUE.equals(redisTemplate.hasKey(LOCK_PREFIX + userId))) {
            throw new InvalidPinException("Account is temporarily locked due to too many failed attempts. Try again later.");
        }
    }

    private void handleFailedAttempt(String userId) {
        String failKey = FAIL_COUNT_PREFIX + userId;
        Long attempts = redisTemplate.opsForValue().increment(failKey);
        
        if (attempts != null && attempts == 1) {
            redisTemplate.expire(failKey, Duration.ofMinutes(LOCK_DURATION_MINUTES));
        }

        if (attempts != null && attempts >= MAX_ATTEMPTS) {
            redisTemplate.opsForValue().set(LOCK_PREFIX + userId, "LOCKED", Duration.ofMinutes(LOCK_DURATION_MINUTES));
            redisTemplate.delete(failKey);
        }
    }
    
    public interface PinUseCaseImpl {
        boolean verifyPin(String userId, String rawPin);
    }
}
