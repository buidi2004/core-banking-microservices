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
@Table(name = "loan_schedule_items", indexes = {
        @Index(name = "idx_loan_schedule_contract", columnList = "loan_contract_id"),
        @Index(name = "idx_loan_schedule_due", columnList = "due_date")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoanScheduleItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "loan_contract_id", nullable = false)
    private UUID loanContractId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "loan_contract_id", insertable = false, updatable = false)
    private LoanContract loanContract;

    @Column(name = "term_number", nullable = false)
    private Integer termNumber;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "principal_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal principalAmount;

    @Column(name = "interest_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal interestAmount;

    @Column(name = "total_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalAmount;

    @Column(name = "remaining_balance", precision = 19, scale = 2, nullable = false)
    private BigDecimal remainingBalance;

    @Column(name = "status", length = 20, nullable = false)
    @Builder.Default
    private String status = "UPCOMING";

    @Column(name = "paid_date")
    private LocalDate paidDate;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}

