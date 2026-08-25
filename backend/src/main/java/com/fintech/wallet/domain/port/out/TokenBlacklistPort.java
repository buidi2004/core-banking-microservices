package com.fintech.wallet.domain.port.out;

/**
 * Output Port: token blacklist store.
 * Allows the application layer to revoke JWT tokens without depending on Redis directly.
 */
public interface TokenBlacklistPort {

    /** Blacklist a token until its natural expiry time. */
    void blacklist(String token, long ttlSeconds);

    /** Returns true if the token has been explicitly revoked. */
    boolean isBlacklisted(String token);
}
