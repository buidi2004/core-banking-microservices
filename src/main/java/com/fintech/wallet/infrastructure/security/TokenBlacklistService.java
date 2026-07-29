package com.fintech.wallet.infrastructure.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
public class TokenBlacklistService {

    private static final Logger log = LoggerFactory.getLogger(TokenBlacklistService.class);

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    public void blacklistToken(String token, long expirationMillis) {
        if (redisTemplate == null || token == null || token.isBlank()) {
            return;
        }
        try {
            String key = "blacklist:token:" + token;
            redisTemplate.opsForValue().set(key, "revoked", Duration.ofMillis(expirationMillis));
        } catch (Exception e) {
            log.warn("Failed to blacklist token in Redis: {}", e.getMessage());
        }
    }

    public boolean isBlacklisted(String token) {
        if (redisTemplate == null || token == null || token.isBlank()) {
            return false;
        }
        try {
            String key = "blacklist:token:" + token;
            return Boolean.TRUE.equals(redisTemplate.hasKey(key));
        } catch (Exception e) {
            log.warn("Failed to check token blacklist in Redis: {}", e.getMessage());
            return false;
        }
    }
}
