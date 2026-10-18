package com.fintech.wallet.domain.port.out;

import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Output Port: abstracts the session key-value store.
 * Allows SessionService to be tested without a real Redis connection.
 */
public interface SessionStorePort {

    /** Store a value under the given key with a TTL. */
    void set(String key, String value, long timeout, TimeUnit unit);

    /** Retrieve a value by key. Returns null if not present. */
    String get(String key);

    /** Delete a single key. */
    void delete(String key);

    /** Delete multiple keys at once. */
    void deleteAll(Set<String> keys);

    /** Return all keys matching the given glob pattern. */
    Set<String> keys(String pattern);
}
