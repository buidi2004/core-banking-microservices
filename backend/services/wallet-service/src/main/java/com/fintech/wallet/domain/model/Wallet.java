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
 * 
 * Tính năng 4.1 — Hạn mức thấu chi (Overdraft Limit):
 * Số dư khả dụng = balance + overdraftLimit. Withdraw cho phép số dư âm
 * tới -overdraftLimit; vượt mức này mới là InsufficientBalanceException.
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
    private Long overdraftLimit;

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
        this(id, ownerId, balance, reservedBalance, createdAt, updatedAt, version, status, dailyLimit, dailySpent, 0L);
    }

    public Wallet(String id, String ownerId, Money balance, BigDecimal reservedBalance,
                  Instant createdAt, Instant updatedAt, Long version,
                  WalletStatus status, Long dailyLimit, Long dailySpent, Long overdraftLimit) {
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
        this.overdraftLimit = overdraftLimit != null ? overdraftLimit : 0L;
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

    /**
     * Rút tiền cho phép chạm vào hạn mức thấu chi: balance + overdraftLimit >= amount.
     * Số dư có thể trở thành âm (dư nợ thấu chi) không vượt quá -overdraftLimit.
     */
    public void withdraw(Money amount) {
        if (amount == null) {
            throw new InvalidMoneyException("Withdrawal amount cannot be null");
        }
        BigDecimal overdraft = overdraftLimit != null ? BigDecimal.valueOf(overdraftLimit) : BigDecimal.ZERO;
        BigDecimal available = this.balance.getAmount().add(overdraft);
        if (available.compareTo(amount.getAmount()) < 0) {
            throw new InsufficientBalanceException("Wallet " + id + " has insufficient balance including overdraft limit ("
                    + balance + ", overdraft_limit=" + overdraft + ") for withdrawal of " + amount);
        }
        this.balance = new Money(this.balance.getAmount().subtract(amount.getAmount()), this.balance.getCurrency());
        this.updatedAt = Instant.now();
    }

    /**
     * Trừ lãi vay thấu chi trên phần dư nợ âm — trừ thẳng vào balance
     * mà không bị giới hạn bởi overdraftLimit (nợ phát sinh vượt hạn mức là hợp đồng lãi).
     */
    public void chargeOverdraftInterest(Money interest) {
        if (interest == null) {
            throw new InvalidMoneyException("Interest amount cannot be null");
        }
        this.balance = this.balance.subtract(interest);
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

    public void setStatus(WalletStatus status) {
        this.status = status;
        this.updatedAt = Instant.now();
    }

    public Long getDailyLimit() {
        return dailyLimit;
    }

    public Long getDailySpent() {
        return dailySpent;
    }

    public Long getOverdraftLimit() {
        return overdraftLimit;
    }

    public void setOverdraftLimit(Long overdraftLimit) {
        this.overdraftLimit = overdraftLimit;
        this.updatedAt = Instant.now();
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
        return "Wallet{id='" + id + "', ownerId='" + ownerId + "', balance=" + balance + ", reserved=" + reservedBalance + ", overdraftLimit=" + overdraftLimit + ", status=" + status + ", version=" + version + "}";
    }
}
