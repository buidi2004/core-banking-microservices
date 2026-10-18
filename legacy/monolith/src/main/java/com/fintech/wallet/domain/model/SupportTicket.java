package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class SupportTicket {
    private final String id;
    private final String userId;
    private final String subject;
    private final String category;
    private String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
    private final Instant createdAt;
    private Instant updatedAt;

    public SupportTicket(String id, String userId, String subject, String category, String status, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.subject = subject;
        this.category = category != null ? category : "GENERAL";
        this.status = status != null ? status : "OPEN";
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
    }

    public static SupportTicket createNew(String userId, String subject, String category) {
        return new SupportTicket(UUID.randomUUID().toString(), userId, subject, category, "OPEN", Instant.now(), Instant.now());
    }

    public void updateStatus(String status) {
        this.status = status;
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getSubject() { return subject; }
    public String getCategory() { return category; }
    public String getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
