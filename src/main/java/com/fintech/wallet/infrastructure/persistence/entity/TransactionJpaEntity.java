package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_transaction_request_id", columnList = "request_id", unique = true)
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TransactionJpaEntity {

    @Id
    private String id;

    @Column(name = "request_id")
    private String requestId;

    @Column(name = "source_wallet_id")
    private String sourceWalletId;

    @Column(name = "target_wallet_id")
    private String targetWalletId;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "type", nullable = false)
    private String type;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
