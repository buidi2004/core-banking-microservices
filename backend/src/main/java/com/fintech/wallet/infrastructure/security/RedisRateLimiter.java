package com.fintech.wallet.infrastructure.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
public class RedisRateLimiter {

    private static final Logger log = LoggerFactory.getLogger(RedisRateLimiter.class);

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    /**
     * Check if request is allowed under rate limit.
     * @param key Rate limit key (e.g. rate:otp:0912345678)
     * @param maxRequests Maximum allowed requests in window
     * @param windowSeconds Window duration in seconds
     * @return true if allowed, false if limit exceeded
     */
    public boolean isAllowed(String key, int maxRequests, long windowSeconds) {
        if (redisTemplate == null) {
            return true; // Fallback to allow if Redis not configured
        }
        try {
            Long currentRequests = redisTemplate.opsForValue().increment(key);
            if (currentRequests != null && currentRequests == 1) {
                redisTemplate.expire(key, Duration.ofSeconds(windowSeconds));
            }
            return currentRequests != null && currentRequests <= maxRequests;
        } catch (Exception e) {
            log.warn("Rate limiter failed to check key {}, allowing request: {}", key, e.getMessage());
            return true;
        }
    }
}
