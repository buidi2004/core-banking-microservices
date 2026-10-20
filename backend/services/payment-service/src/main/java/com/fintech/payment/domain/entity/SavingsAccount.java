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
@Table(name = "savings_accounts", indexes = {
        @Index(name = "idx_savings_user", columnList = "user_id"),
        @Index(name = "idx_savings_account_num", columnList = "account_number", unique = true),
        @Index(name = "idx_savings_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SavingsAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "wallet_id", length = 36, nullable = false)
    private String walletId;

    @Column(name = "account_number", length = 50, nullable = false, unique = true)
    private String accountNumber;

    @Column(name = "product_type", length = 50, nullable = false)
    private String productType;

    @Column(name = "product_name", length = 100, nullable = false)
    private String productName;

    @Column(name = "principal", precision = 19, scale = 2, nullable = false)
    private BigDecimal principal;

    @Column(name = "interest_rate", precision = 5, scale = 2, nullable = false)
    private BigDecimal interestRate;

    @Column(name = "term_months", nullable = false)
    private Integer termMonths;

    @Column(name = "expected_interest", precision = 19, scale = 2, nullable = false)
    private BigDecimal expectedInterest;

    @Column(name = "accrued_interest", precision = 19, scale = 2)
    @Builder.Default
    private BigDecimal accruedInterest = BigDecimal.ZERO;

    @Column(name = "rollover_type", length = 30)
    @Builder.Default
    private String rolloverType = "AUTO_ROLLOVER_ALL";

    @Column(name = "status", length = 20, nullable = false)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "maturity_date", nullable = false)
    private LocalDate maturityDate;

    @Column(name = "settled_date")
    private Instant settledDate;

    @Column(name = "settled_amount", precision = 19, scale = 2)
    private BigDecimal settledAmount;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}

