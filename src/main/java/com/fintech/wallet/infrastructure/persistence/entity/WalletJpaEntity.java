package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "wallets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class WalletJpaEntity {

    @Id
    private String id;

    @Column(name = "owner_id", nullable = false, unique = true)
    private String ownerId;

    @Column(name = "balance_amount", nullable = false)
    private BigDecimal balanceAmount;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private Long version;
}
