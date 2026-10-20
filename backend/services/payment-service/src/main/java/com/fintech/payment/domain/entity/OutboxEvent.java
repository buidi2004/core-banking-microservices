package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: OutboxEvent (ewallet_payment_db)
 * Mẫu Transactional Outbox đảm bảo gửi sự kiện tin cậy lên RabbitMQ.
 */
@Entity
@Table(name = "outbox_events", indexes = {
        @Index(name = "idx_outbox_status_created", columnList = "status, created_at"),
        @Index(name = "idx_outbox_aggregate", columnList = "aggregate_type, aggregate_id")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class OutboxEvent {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "aggregate_type", length = 50, nullable = false)
    private String aggregateType;

    @Column(name = "aggregate_id", length = 36, nullable = false)
    private String aggregateId;

    @Column(name = "event_type", length = 100, nullable = false)
    private String eventType;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "payload", columnDefinition = "jsonb", nullable = false)
    private String payload;

    @Column(nullable = false, length = 20, columnDefinition = "varchar(20) default 'PENDING'")
    private String status;

    @Column(name = "retry_count", nullable = false, columnDefinition = "int default 0")
    private Integer retryCount;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "published_at")
    private Instant publishedAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (status == null) status = "PENDING";
        if (retryCount == null) retryCount = 0;
    }

    public static OutboxEvent pending(String aggregateType, String aggregateId, String eventType, String payload) {
        return OutboxEvent.builder()
                .aggregateType(aggregateType)
                .aggregateId(aggregateId)
                .eventType(eventType)
                .payload(payload)
                .status("PENDING")
                .retryCount(0)
                .build();
    }

    public void markPublished() { this.status = "PUBLISHED"; this.publishedAt = Instant.now(); }
    public void markFailed() { this.status = "FAILED"; }
    public void incrementRetry() { if (this.retryCount == null) this.retryCount = 0; this.retryCount++; }
}
