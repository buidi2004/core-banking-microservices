package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "wallets")
public class WalletJpaEntity {

    @Id
    private String id;

    @Column(name = "user_id", nullable = false, unique = true)
    private String ownerId;

    @Column(name = "balance_amount", nullable = false)
    private BigDecimal balanceAmount;

    @Column(name = "reserved_balance", nullable = false)
    private BigDecimal reservedBalance;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "daily_limit")
    private Long dailyLimit;

    @Column(name = "daily_spent")
    private Long dailySpent;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private Long version;

    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }

    public String getOwnerId() {
        return ownerId;
    }
    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }

    public BigDecimal getBalanceAmount() {
        return balanceAmount;
    }
    public void setBalanceAmount(BigDecimal balanceAmount) {
        this.balanceAmount = balanceAmount;
    }

    public BigDecimal getReservedBalance() {
        return reservedBalance;
    }
    public void setReservedBalance(BigDecimal reservedBalance) {
        this.reservedBalance = reservedBalance;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public Long getDailyLimit() {
        return dailyLimit;
    }
    public void setDailyLimit(Long dailyLimit) {
        this.dailyLimit = dailyLimit;
    }

    public Long getDailySpent() {
        return dailySpent;
    }
    public void setDailySpent(Long dailySpent) {
        this.dailySpent = dailySpent;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Long getVersion() {
        return version;
    }
    public void setVersion(Long version) {
        this.version = version;
    }

    public WalletJpaEntity() {}

    public WalletJpaEntity(String id, String ownerId, BigDecimal balanceAmount, BigDecimal reservedBalance,
                           String currency, String status, Long dailyLimit, Long dailySpent,
                           Instant createdAt, Instant updatedAt, Long version) {
        this.id = id;
        this.ownerId = ownerId;
        this.balanceAmount = balanceAmount;
        this.reservedBalance = reservedBalance;
        this.currency = currency;
        this.status = status;
        this.dailyLimit = dailyLimit;
        this.dailySpent = dailySpent;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.version = version;
    }
}
