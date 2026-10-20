package com.fintech.wallet.infrastructure.cache;

import com.fintech.wallet.domain.exception.LockAcquisitionException;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Supplier;

/**
 * Adapter: RedisLockAdapter
 * Implements DistributedLockPort to prevent race conditions during concurrent wallet transactions.
 * Uses Redis setIfAbsent for distributed lock, falling back to local JVM locks ONLY when Redis connection fails.
 *
 * Fixes applied:
 * - BUG #2: Atomic unlock via Lua script (compare-and-delete)
 * - ISSUE #8: LRU eviction skips locks that are currently held
 * - OPT #2: Exponential backoff with jitter for retry
 */
@Component
public class RedisLockAdapter implements DistributedLockPort {

    private static final Logger log = LoggerFactory.getLogger(RedisLockAdapter.class);

    @Autowired(required = false)
    private StringRedisTemplate redisTemplate;

    private static final int MAX_LOCAL_LOCKS = 10_000;

    // BUG #2 fix: Lua script for atomic compare-and-delete unlock.
    // Prevents deleting a lock acquired by another process after TTL expiry.
    private static final String UNLOCK_LUA_SCRIPT =
        "if redis.call('get', KEYS[1]) == ARGV[1] then " +
        "  return redis.call('del', KEYS[1]) " +
        "else " +
        "  return 0 " +
        "end";

    private static final DefaultRedisScript<Long> UNLOCK_SCRIPT =
            new DefaultRedisScript<>(UNLOCK_LUA_SCRIPT, Long.class);

    // ISSUE #8 fix: Don't evict locks that are currently held by any thread
    private final Map<String, ReentrantLock> localLocks =
            Collections.synchronizedMap(
                    new java.util.LinkedHashMap<String, ReentrantLock>(256, 0.75f, true) {
                        @Override
                        protected boolean removeEldestEntry(Map.Entry<String, ReentrantLock> eldest) {
                            return size() > MAX_LOCAL_LOCKS && !eldest.getValue().isLocked();
                        }
                    });

    @Override
    public <T> T executeWithLock(String lockKey, long timeoutSeconds, Supplier<T> supplier) {
        if (redisTemplate != null) {
            try {
                return executeWithRedisLock(lockKey, timeoutSeconds, supplier);
            } catch (DataAccessException e) {
                log.warn("Redis infrastructure error for key {}, falling back to local JVM lock: {}", lockKey, e.getMessage());
            }
        }
        return executeWithLocalLock(lockKey, supplier);
    }

    private <T> T executeWithRedisLock(String lockKey, long timeoutSeconds, Supplier<T> supplier) {
        String lockValue = UUID.randomUUID().toString();
        int maxRetries = 10;
        boolean acquired = false;

        // OPT #2: Exponential backoff with jitter to reduce thundering herd
        for (int i = 0; i < maxRetries; i++) {
            Boolean result = redisTemplate.opsForValue()
                    .setIfAbsent(lockKey, lockValue, Duration.ofSeconds(timeoutSeconds));

            if (Boolean.TRUE.equals(result)) {
                acquired = true;
                break;
            }

            try {
                long backoffMs = Math.min(100L * (1L << i), 2000L)
                        + ThreadLocalRandom.current().nextLong(50);
                Thread.sleep(backoffMs);
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw new LockAcquisitionException("Thread interrupted while waiting for lock on key: " + lockKey, ie);
            }
        }

        if (acquired) {
            try {
                return supplier.get();
            } finally {
                // BUG #2 fix: Atomic compare-and-delete using Lua script.
                // Ensures we only delete our own lock, not one acquired by another process.
                try {
                    redisTemplate.execute(UNLOCK_SCRIPT, List.of(lockKey), lockValue);
                } catch (Exception e) {
                    log.error("Failed to release Redis lock for key: {}", lockKey, e);
                }
            }
        } else {
            throw new LockAcquisitionException("Could not acquire lock for resource (busy): " + lockKey);
        }
    }

    private <T> T executeWithLocalLock(String lockKey, Supplier<T> supplier) {
        ReentrantLock lock;
        synchronized (localLocks) {
            lock = localLocks.get(lockKey);
            if (lock == null) {
                lock = new ReentrantLock();
                localLocks.put(lockKey, lock);
            }
        }
        lock.lock();
        try {
            return supplier.get();
        } finally {
            lock.unlock();
        }
    }
}
