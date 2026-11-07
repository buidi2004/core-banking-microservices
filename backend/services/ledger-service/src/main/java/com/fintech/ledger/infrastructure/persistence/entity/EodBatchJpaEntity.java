package com.fintech.ledger.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "eod_batches")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EodBatchJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "batch_id", unique = true, nullable = false, length = 64)
    private String batchId;

    @Column(name = "value_date", nullable = false)
    private LocalDate valueDate;

    @Column(name = "next_value_date", nullable = false)
    private LocalDate nextValueDate;

    @Column(name = "total_debit", nullable = false, precision = 19, scale = 2)
    private BigDecimal totalDebit;

    @Column(name = "total_credit", nullable = false, precision = 19, scale = 2)
    private BigDecimal totalCredit;

    @Column(name = "delta", nullable = false, precision = 19, scale = 2)
    private BigDecimal delta;

    @Column(name = "is_balanced", nullable = false)
    private boolean isBalanced;

    @Column(name = "total_entries", nullable = false)
    private long totalEntries;

    @Column(name = "total_postings", nullable = false)
    private long totalPostings;

    @Column(name = "checksum_passed", nullable = false)
    private boolean checksumPassed;

    @Column(name = "corrupted_accounts", nullable = false)
    private int corruptedAccounts;

    @Column(name = "maker_checker_pending", nullable = false)
    private int makerCheckerPending;

    @Column(name = "outbox_pending", nullable = false)
    private int outboxPending;

    @Column(name = "status", nullable = false, length = 30)
    private String status;

    @Column(name = "executed_by", nullable = false, length = 64)
    private String executedBy;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
