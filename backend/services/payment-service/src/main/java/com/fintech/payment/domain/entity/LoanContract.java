package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "loan_contracts", indexes = {
        @Index(name = "idx_loan_user", columnList = "user_id"),
        @Index(name = "idx_loan_contract_num", columnList = "contract_number", unique = true),
        @Index(name = "idx_loan_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoanContract {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "wallet_id", length = 36, nullable = false)
    private String walletId;

    @Column(name = "contract_number", length = 50, nullable = false, unique = true)
    private String contractNumber;

    @Column(name = "product_type", length = 50, nullable = false)
    private String productType;

    @Column(name = "product_name", length = 100, nullable = false)
    private String productName;

    @Column(name = "principal_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal principalAmount;

    @Column(name = "annual_interest_rate", precision = 5, scale = 2, nullable = false)
    private BigDecimal annualInterestRate;

    @Column(name = "term_months", nullable = false)
    private Integer termMonths;

    @Column(name = "total_interest", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalInterest;

    @Column(name = "total_repayment", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalRepayment;

    @Column(name = "remaining_principal", precision = 19, scale = 2, nullable = false)
    private BigDecimal remainingPrincipal;

    @Column(name = "monthly_payment", precision = 19, scale = 2, nullable = false)
    private BigDecimal monthlyPayment;

    @Column(name = "purpose", length = 255)
    private String purpose;

    @Column(name = "status", length = 20, nullable = false)
    @Builder.Default
    private String status = "DISBURSED";

    @Column(name = "disbursed_at")
    private Instant disbursedAt;

    @Column(name = "first_due_date")
    private LocalDate firstDueDate;

    @OneToMany(mappedBy = "loanContract", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<LoanScheduleItem> scheduleItems = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}

