package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class LegalConsent {
    private final String id;
    private final String userId;
    private final String termsVersion;
    private final String ipAddress;
    private final String userAgent;
    private final Instant agreedAt;

    public LegalConsent(String id, String userId, String termsVersion, String ipAddress, String userAgent, Instant agreedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.termsVersion = termsVersion;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.agreedAt = agreedAt != null ? agreedAt : Instant.now();
    }

    public static LegalConsent createNew(String userId, String termsVersion, String ipAddress, String userAgent) {
        return new LegalConsent(UUID.randomUUID().toString(), userId, termsVersion, ipAddress, userAgent, Instant.now());
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getTermsVersion() { return termsVersion; }
    public String getIpAddress() { return ipAddress; }
    public String getUserAgent() { return userAgent; }
    public Instant getAgreedAt() { return agreedAt; }
}
