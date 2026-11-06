package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "scheduled_transfers")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledTransfer {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "source_user_id", nullable = false, length = 36)
    private String sourceUserId;

    @Column(name = "target_user_id", nullable = false, length = 36)
    private String targetUserId;

    @Column(name = "target_phone_number", length = 20)
    private String targetPhoneNumber;

    @Column(name = "target_customer_name", length = 100)
    private String targetCustomerName;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false, length = 10)
    @Builder.Default
    private String currency = "VND";

    @Column(length = 255)
    private String note;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String frequency = "ONCE"; // ONCE, DAILY, WEEKLY, MONTHLY

    @Column(name = "day_of_month")
    private Integer dayOfMonth;

    @Column(name = "next_execution_at", nullable = false)
    private Instant nextExecutionAt;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, COMPLETED, CANCELLED, FAILED

    @Column(name = "last_executed_at")
    private Instant lastExecutedAt;

    @Column(name = "last_transaction_id", length = 36)
    private String lastTransactionId;

    @Column(name = "failure_reason", length = 255)
    private String failureReason;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}

