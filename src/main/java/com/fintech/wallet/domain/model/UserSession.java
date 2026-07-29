package com.fintech.wallet.domain.model;

import java.time.Instant;

public class UserSession {
    private final String sessionId;
    private final String userId;
    private final String deviceInfo;
    private final String ipAddress;
    private final Instant createdAt;
    private final Instant lastActiveAt;

    public UserSession(String sessionId, String userId, String deviceInfo, String ipAddress, Instant createdAt, Instant lastActiveAt) {
        this.sessionId = sessionId;
        this.userId = userId;
        this.deviceInfo = deviceInfo;
        this.ipAddress = ipAddress;
        this.createdAt = createdAt;
        this.lastActiveAt = lastActiveAt;
    }

    public String getSessionId() { return sessionId; }
    public String getUserId() { return userId; }
    public String getDeviceInfo() { return deviceInfo; }
    public String getIpAddress() { return ipAddress; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getLastActiveAt() { return lastActiveAt; }
}
