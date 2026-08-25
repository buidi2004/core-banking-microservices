package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class DeviceToken {
    private final String id;
    private final String userId;
    private final String deviceId;
    private final String fcmToken;
    private final Instant registeredAt;

    public DeviceToken(String id, String userId, String deviceId, String fcmToken, Instant registeredAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.deviceId = deviceId;
        this.fcmToken = fcmToken;
        this.registeredAt = registeredAt != null ? registeredAt : Instant.now();
    }

    public static DeviceToken createNew(String userId, String deviceId, String fcmToken) {
        return new DeviceToken(UUID.randomUUID().toString(), userId, deviceId, fcmToken, Instant.now());
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getDeviceId() { return deviceId; }
    public String getFcmToken() { return fcmToken; }
    public Instant getRegisteredAt() { return registeredAt; }
}
