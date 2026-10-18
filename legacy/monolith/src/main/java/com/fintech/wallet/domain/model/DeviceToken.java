package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class DeviceToken {
    private final String id;
    private final String userId;
    private final String fcmToken;
    private final String deviceType;
    private final Instant createdAt;
    private final Instant updatedAt;

    public DeviceToken(String id, String userId, String fcmToken, String deviceType, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.fcmToken = fcmToken;
        this.deviceType = deviceType != null ? deviceType : "ANDROID";
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
    }

    public static DeviceToken createNew(String userId, String fcmToken, String deviceType) {
        Instant now = Instant.now();
        return new DeviceToken(UUID.randomUUID().toString(), userId, fcmToken, deviceType, now, now);
    }

    public DeviceToken updateOwner(String newUserId, String newDeviceType) {
        return new DeviceToken(
                this.id,
                newUserId,
                this.fcmToken,
                newDeviceType != null ? newDeviceType : this.deviceType,
                this.createdAt,
                Instant.now()
        );
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getFcmToken() { return fcmToken; }
    public String getDeviceType() { return deviceType; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}

