package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class AppFeedback {
    private final String id;
    private final String userId;
    private final int rating; // 1-5 stars
    private final String comment;
    private final Instant createdAt;

    public AppFeedback(String id, String userId, int rating, String comment, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.rating = rating;
        this.comment = comment;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static AppFeedback createNew(String userId, int rating, String comment) {
        return new AppFeedback(UUID.randomUUID().toString(), userId, rating, comment, Instant.now());
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public int getRating() { return rating; }
    public String getComment() { return comment; }
    public Instant getCreatedAt() { return createdAt; }
}
