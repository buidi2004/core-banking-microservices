package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "dispute_cases")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DisputeCase {

    public static final String STATUS_OPEN = "OPEN";
    public static final String STATUS_UNDER_REVIEW = "UNDER_REVIEW";
    public static final String STATUS_APPROVED_REFUND = "APPROVED_REFUND";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_REVERSED = "REVERSED";

    @Id
    private UUID id;

    @Column(name = "transaction_id", nullable = false, length = 100)
    private String transactionId;

    @Column(name = "customer_id", length = 100)
    private String customerId;

    @Column(name = "dispute_type", nullable = false, length = 50)
    private String disputeType;

    @Column(nullable = false, length = 1000)
    private String reason;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "refund_amount", nullable = false)
    private Long refundAmount;

    @Column(name = "resolution_note", length = 1000)
    private String resolutionNote;

    @Column(name = "created_by", nullable = false, length = 100)
    private String createdBy;

    @Column(name = "assigned_to", length = 100)
    private String assignedTo;

    @Column(name = "resolved_by", length = 100)
    private String resolvedBy;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;
}

