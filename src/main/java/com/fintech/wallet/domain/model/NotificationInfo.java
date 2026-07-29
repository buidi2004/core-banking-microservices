package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class NotificationInfo {
    private final String id;
    private final String userId;
    private final String title;
    private final String content;
    private final String type;
    private boolean read;
    private final Instant createdAt;

    public NotificationInfo(String id, String userId, String title, String content, String type, boolean read, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.title = title;
        this.content = content;
        this.type = type != null ? type : "GENERAL";
        this.read = read;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static NotificationInfo createNew(String userId, String title, String content, String type) {
        return new NotificationInfo(UUID.randomUUID().toString(), userId, title, content, type, false, Instant.now());
    }

    public void markAsRead() {
        this.read = true;
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public String getType() { return type; }
    public boolean isRead() { return read; }
    public Instant getCreatedAt() { return createdAt; }
}
