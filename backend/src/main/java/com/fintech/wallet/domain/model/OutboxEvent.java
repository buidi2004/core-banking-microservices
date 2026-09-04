package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class OutboxEvent {
    private String id;
    private String aggregateType;
    private String aggregateId;
    private String type;
    private String payload;
    private OutboxEventStatus status;
    private Instant createdAt;
    private int retryCount;

    public enum OutboxEventStatus {
        PENDING,
        PROCESSED,
        FAILED
    }

    public OutboxEvent(String id, String aggregateType, String aggregateId, String type, String payload, OutboxEventStatus status, Instant createdAt, int retryCount) {
        this.id = id;
        this.aggregateType = aggregateType;
        this.aggregateId = aggregateId;
        this.type = type;
        this.payload = payload;
        this.status = status;
        this.createdAt = createdAt;
        this.retryCount = retryCount;
    }

    public static OutboxEvent create(String aggregateType, String aggregateId, String type, String payload) {
        return new OutboxEvent(
                UUID.randomUUID().toString(),
                aggregateType,
                aggregateId,
                type,
                payload,
                OutboxEventStatus.PENDING,
                Instant.now(),
                0
        );
    }

    public void markProcessed() {
        this.status = OutboxEventStatus.PROCESSED;
    }

    public void markFailed() {
        this.status = OutboxEventStatus.FAILED;
    }

    public String getId() { return id; }
    public String getAggregateType() { return aggregateType; }
    public String getAggregateId() { return aggregateId; }
    public String getType() { return type; }
    public String getPayload() { return payload; }
    public OutboxEventStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public int getRetryCount() { return retryCount; }
    public void incrementRetryCount() { this.retryCount++; }
}
