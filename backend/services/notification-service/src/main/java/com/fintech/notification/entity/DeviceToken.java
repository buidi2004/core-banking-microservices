package com.fintech.notification.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "device_tokens")
public class DeviceToken {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    @Column(name = "platform", nullable = false, length = 20)
    private String platform;

    @Column(name = "token", nullable = false, length = 512)
    private String token;

    @Column(name = "device_model", length = 255)
    private String deviceModel;

    @Column(name = "app_version", length = 50)
    private String appVersion;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public DeviceToken() {
    }

    @PrePersist
    void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public static DeviceToken create(String userId, String platform, String token, String deviceModel, String appVersion) {
        DeviceToken d = new DeviceToken();
        d.userId = userId;
        d.platform = platform != null ? platform : "FCM";
        d.token = token;
        d.deviceModel = deviceModel;
        d.appVersion = appVersion;
        d.active = true;
        return d;
    }

    public void assignTo(String userId, String platform) {
        this.userId = userId;
        if (platform != null && !platform.isBlank()) {
            this.platform = platform;
        }
        this.active = true;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public String getDeviceModel() { return deviceModel; }
    public void setDeviceModel(String deviceModel) { this.deviceModel = deviceModel; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
