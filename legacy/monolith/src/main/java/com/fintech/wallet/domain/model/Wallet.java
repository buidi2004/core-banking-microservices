package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.exception.InvalidMoneyException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: Wallet
 * Pure Java - No Spring / JPA annotations.
 */
public class Wallet {
    private final String id;
    private final String ownerId;
    private Money balance;
    private BigDecimal reservedBalance;
    private final Instant createdAt;
    private Instant updatedAt;
    private Long version;
    private WalletStatus status;
    private Long dailyLimit;
    private Long dailySpent;

    public Wallet(String id, String ownerId, Money balance, Instant createdAt, Instant updatedAt, Long version) {
        this(id, ownerId, balance, BigDecimal.ZERO, createdAt, updatedAt, version, WalletStatus.ACTIVE, 50000000L, 0L);
    }

    public Wallet(String id, String ownerId, Money balance, Instant createdAt, Instant updatedAt, Long version,
                  WalletStatus status, Long dailyLimit, Long dailySpent) {
        this(id, ownerId, balance, BigDecimal.ZERO, createdAt, updatedAt, version, status, dailyLimit, dailySpent);
    }

    public Wallet(String id, String ownerId, Money balance, BigDecimal reservedBalance,
                  Instant createdAt, Instant updatedAt, Long version,
                  WalletStatus status, Long dailyLimit, Long dailySpent) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.ownerId = ownerId;
        this.balance = balance != null ? balance : Money.zero("VND");
        this.reservedBalance = reservedBalance != null ? reservedBalance : BigDecimal.ZERO;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
        this.version = version;
        this.status = status != null ? status : WalletStatus.ACTIVE;
        this.dailyLimit = dailyLimit;
        this.dailySpent = dailySpent;
    }

    public static Wallet createNew(String ownerId, String currency) {
        return new Wallet(
            UUID.randomUUID().toString(),
            ownerId,
            Money.zero(currency),
            Instant.now(),
            Instant.now(),
            null,
            WalletStatus.ACTIVE,
            50000000L,
            0L
        );
    }

    public void deposit(Money amount) {
        if (amount == null) {
            throw new InvalidMoneyException("Deposit amount cannot be null");
        }
        this.balance = this.balance.add(amount);
        this.updatedAt = Instant.now();
    }

    public void withdraw(Money amount) {
        if (amount == null) {
            throw new InvalidMoneyException("Withdrawal amount cannot be null");
        }
        if (!this.balance.isGreaterThanOrEqual(amount)) {
            throw new InsufficientBalanceException("Wallet " + id + " has insufficient balance (" + balance + ") for withdrawal of " + amount);
        }
        this.balance = this.balance.subtract(amount);
        this.updatedAt = Instant.now();
    }

    public boolean isActive() {
        return this.status == WalletStatus.ACTIVE;
    }

    public String getId() {
        return id;
    }

    public String getOwnerId() {
        return ownerId;
    }

    public Money getBalance() {
        return balance;
    }

    public BigDecimal getReservedBalance() {
        return reservedBalance;
    }

    public void setReservedBalance(BigDecimal reservedBalance) {
        this.reservedBalance = reservedBalance;
        this.updatedAt = Instant.now();
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Long getVersion() {
        return version;
    }

    public WalletStatus getStatus() {
        return status;
    }

    public Long getDailyLimit() {
        return dailyLimit;
    }

    public Long getDailySpent() {
        return dailySpent;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Wallet wallet = (Wallet) o;
        return Objects.equals(id, wallet.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "Wallet{id='" + id + "', ownerId='" + ownerId + "', balance=" + balance + ", reserved=" + reservedBalance + ", status=" + status + ", version=" + version + "}";
    }
}
