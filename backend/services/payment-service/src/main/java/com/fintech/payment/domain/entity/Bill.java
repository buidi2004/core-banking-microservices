package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "bills", indexes = {
        @Index(name = "idx_bills_customer", columnList = "customer_code, status"),
        @Index(name = "idx_bills_bill_id", columnList = "bill_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Bill {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(name = "bill_id", length = 64, nullable = false, unique = true)
    private String billId;

    @Column(name = "service_type", length = 30, nullable = false)
    private String serviceType; // ELECTRICITY, WATER, INTERNET, TELCO_POSTPAID

    @Column(name = "provider_code", length = 50, nullable = false)
    private String providerCode;

    @Column(name = "customer_code", length = 50, nullable = false)
    private String customerCode;

    @Column(name = "customer_name", length = 100, nullable = false)
    private String customerName;

    @Column(name = "customer_address", length = 255)
    private String customerAddress;

    @Column(name = "period", length = 30, nullable = false)
    private String period;

    @Column(name = "amount", precision = 19, scale = 4, nullable = false)
    private BigDecimal amount;

    @Column(name = "fee", precision = 19, scale = 4, nullable = false)
    private BigDecimal fee;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "status", length = 20, nullable = false)
    private String status; // UNPAID, PAID, CANCELLED

    @Column(name = "paid_at")
    private Instant paidAt;

    @Column(name = "paid_by_user_id", length = 36)
    private String paidByUserId;

    @Column(name = "transaction_id", length = 36)
    private String transactionId;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (updatedAt == null) updatedAt = Instant.now();
        if (status == null) status = "UNPAID";
        if (fee == null) fee = BigDecimal.ZERO;
    }
}

