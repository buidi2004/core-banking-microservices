package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class NotificationInfo {
    private final String id;
    private final String userId;
    private final String title;
    private final String content;
    private final NotificationType type;
    private boolean read;
    private final Instant createdAt;
    private final String metadata;

    public NotificationInfo(String id, String userId, String title, String content, NotificationType type, boolean read, Instant createdAt, String metadata) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.title = title;
        this.content = content;
        this.type = type != null ? type : NotificationType.SYSTEM;
        this.read = read;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.metadata = metadata;
    }

    public static NotificationInfo createNew(String userId, String title, String content, NotificationType type, String metadata) {
        return new NotificationInfo(UUID.randomUUID().toString(), userId, title, content, type, false, Instant.now(), metadata);
    }

    public void markAsRead() {
        this.read = true;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public NotificationType getType() { return type; }
    public boolean isRead() { return read; }
    public Instant getCreatedAt() { return createdAt; }
    public String getMetadata() { return metadata; }
}
