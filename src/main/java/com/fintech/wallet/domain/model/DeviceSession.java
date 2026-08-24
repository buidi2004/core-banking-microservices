package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class DeviceSession {
    private final String id;
    private final String userId;
    private final String deviceId;
    private String fcmToken;
    private String refreshToken;
    private String ipAddress;
    private String userAgent;
    private boolean active;
    private final Instant createdAt;
    private Instant lastActiveAt;
    private final Instant expiresAt;

    public DeviceSession(String id, String userId, String deviceId, String fcmToken, String refreshToken, 
                         String ipAddress, String userAgent, boolean active, 
                         Instant createdAt, Instant lastActiveAt, Instant expiresAt) {
        this.id = id;
        this.userId = userId;
        this.deviceId = deviceId;
        this.fcmToken = fcmToken;
        this.refreshToken = refreshToken;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.active = active;
        this.createdAt = createdAt;
        this.lastActiveAt = lastActiveAt;
        this.expiresAt = expiresAt;
    }

    public static DeviceSession createNew(String userId, String deviceId, String ipAddress, String userAgent, Instant expiresAt) {
        return new DeviceSession(
                UUID.randomUUID().toString(),
                userId,
                deviceId,
                null,
                null,
                ipAddress,
                userAgent,
                true,
                Instant.now(),
                Instant.now(),
                expiresAt
        );
    }

    public void updateFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
        this.lastActiveAt = Instant.now();
    }

    public void assignRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
        this.lastActiveAt = Instant.now();
    }

    public void revoke() {
        this.active = false;
        this.refreshToken = null;
        this.fcmToken = null;
        this.lastActiveAt = Instant.now();
    }

    public void markActive() {
        this.lastActiveAt = Instant.now();
    }

    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }

    // Getters
    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getDeviceId() { return deviceId; }
    public String getFcmToken() { return fcmToken; }
    public String getRefreshToken() { return refreshToken; }
    public String getIpAddress() { return ipAddress; }
    public String getUserAgent() { return userAgent; }
    public boolean isActive() { return active && !isExpired(); }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getLastActiveAt() { return lastActiveAt; }
    public Instant getExpiresAt() { return expiresAt; }
}
