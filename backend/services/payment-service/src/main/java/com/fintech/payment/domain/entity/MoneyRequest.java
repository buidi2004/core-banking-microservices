package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: MoneyRequest (ewallet_payment_db)
 * Yêu cầu chia tiền P2P (một user yêu cầu user khác gửi tiền).
 */
@Entity
@Table(name = "money_requests", indexes = {
        @Index(name = "idx_money_requests_requester", columnList = "requester_id, created_at DESC"),
        @Index(name = "idx_money_requests_target", columnList = "target_user_id, created_at DESC"),
        @Index(name = "idx_money_requests_status", columnList = "status")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MoneyRequest {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "requester_id", length = 36, nullable = false)
    private String requesterId;

    @Column(name = "target_user_id", length = 36, nullable = false)
    private String targetUserId;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false, length = 20, columnDefinition = "varchar(20) default 'PENDING'")
    private String status;

    @Column(columnDefinition = "text")
    private String note;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (status == null) status = "PENDING";
    }

    public static MoneyRequest create(String requesterId, String targetUserId, Long amount, Instant expiresAt, String note) {
        return MoneyRequest.builder()
                .requesterId(requesterId)
                .targetUserId(targetUserId)
                .amount(amount)
                .status("PENDING")
                .note(note)
                .expiresAt(expiresAt)
                .build();
    }

    public void accept() { this.status = "ACCEPTED"; }
    public void reject() { this.status = "REJECTED"; }
    public void expire() { this.status = "EXPIRED"; }
}
