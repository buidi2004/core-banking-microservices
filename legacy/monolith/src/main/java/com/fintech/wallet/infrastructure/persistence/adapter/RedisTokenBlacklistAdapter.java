package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.port.out.TokenBlacklistPort;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * Infrastructure adapter: stores revoked JWT tokens in Redis with TTL matching
 * the token's remaining validity so memory is reclaimed automatically.
 */
@Component
public class RedisTokenBlacklistAdapter implements TokenBlacklistPort {

    private static final String PREFIX = "blacklist:token:";

    private final StringRedisTemplate redisTemplate;

    public RedisTokenBlacklistAdapter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void blacklist(String token, long ttlSeconds) {
        if (ttlSeconds > 0) {
            redisTemplate.opsForValue()
                    .set(PREFIX + token, "1", Duration.ofSeconds(ttlSeconds));
        }
    }

    @Override
    public boolean isBlacklisted(String token) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(PREFIX + token));
    }
}
