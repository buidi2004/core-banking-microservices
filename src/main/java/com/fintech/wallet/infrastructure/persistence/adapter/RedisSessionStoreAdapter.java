package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.port.out.SessionStorePort;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Infrastructure Adapter: wraps StringRedisTemplate for session storage.
 * Implements the domain-level SessionStorePort so application services
 * never depend on Spring Redis classes directly.
 */
@Component
public class RedisSessionStoreAdapter implements SessionStorePort {

    private final StringRedisTemplate redisTemplate;

    public RedisSessionStoreAdapter(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void set(String key, String value, long timeout, TimeUnit unit) {
        redisTemplate.opsForValue().set(key, value, timeout, unit);
    }

    @Override
    public String get(String key) {
        return redisTemplate.opsForValue().get(key);
    }

    @Override
    public void delete(String key) {
        redisTemplate.delete(key);
    }

    @Override
    public void deleteAll(Set<String> keys) {
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
    }

    @Override
    public Set<String> keys(String pattern) {
        Set<String> result = redisTemplate.keys(pattern);
        return result != null ? result : Collections.emptySet();
    }
}
