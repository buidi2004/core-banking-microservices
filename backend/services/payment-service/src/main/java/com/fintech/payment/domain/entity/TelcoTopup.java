package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "telco_topups", indexes = {
        @Index(name = "idx_telco_topups_user", columnList = "user_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TelcoTopup {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "phone_number", length = 20, nullable = false)
    private String phoneNumber;

    @Column(name = "telco_code", length = 30, nullable = false)
    private String telcoCode;

    @Column(name = "topup_amount", precision = 19, scale = 4, nullable = false)
    private BigDecimal topupAmount;

    @Column(name = "discount_amount", precision = 19, scale = 4, nullable = false)
    private BigDecimal discountAmount;

    @Column(name = "net_amount", precision = 19, scale = 4, nullable = false)
    private BigDecimal netAmount;

    @Column(name = "status", length = 20, nullable = false)
    private String status; // SUCCESS, FAILED

    @Column(name = "transaction_id", length = 36)
    private String transactionId;

    @Column(name = "serial_number", length = 64)
    private String serialNumber;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (status == null) status = "SUCCESS";
        if (discountAmount == null) discountAmount = BigDecimal.ZERO;
        if (serialNumber == null) serialNumber = "TOPUP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}

