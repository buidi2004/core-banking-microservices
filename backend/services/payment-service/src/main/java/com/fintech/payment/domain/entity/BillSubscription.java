package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "bill_subscriptions", indexes = {
        @Index(name = "idx_bill_sub_user", columnList = "user_id"),
        @Index(name = "idx_bill_sub_status_day", columnList = "status, auto_debit_day")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BillSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "wallet_id", length = 36, nullable = false)
    private String walletId;

    @Column(name = "bill_type", length = 50, nullable = false)
    private String billType;

    @Column(name = "customer_code", length = 100, nullable = false)
    private String customerCode;

    @Column(name = "provider_code", length = 50, nullable = false)
    private String providerCode;

    @Column(name = "auto_debit_day", nullable = false)
    @Builder.Default
    private Integer autoDebitDay = 5;

    @Column(name = "status", length = 20, nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "last_deducted_at")
    private Instant lastDeductedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}

