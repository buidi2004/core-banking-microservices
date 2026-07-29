package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.exception.InvalidMoneyException;

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
    private final Instant createdAt;
    private Instant updatedAt;
    private Long version;

    public Wallet(String id, String ownerId, Money balance, Instant createdAt, Instant updatedAt, Long version) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.ownerId = ownerId;
        this.balance = balance != null ? balance : Money.zero("USD");
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
        this.version = version;
    }

    public Wallet(String id, String ownerId, Money balance, Instant createdAt, Instant updatedAt) {
        this(id, ownerId, balance, createdAt, updatedAt, null);
    }

    public static Wallet createNew(String ownerId, String currency) {
        return new Wallet(
            UUID.randomUUID().toString(),
            ownerId,
            Money.zero(currency),
            Instant.now(),
            Instant.now()
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
        // Use subtract directly — we already validated balance >= amount above,
        // so Money.subtract()'s internal isLessThan check will always pass.
        // This ensures only InsufficientBalanceException is thrown, never InvalidMoneyException for the same condition.
        this.balance = this.balance.subtract(amount);
        this.updatedAt = Instant.now();
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

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Long getVersion() {
        return version;
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
        return "Wallet{id='" + id + "', ownerId='" + ownerId + "', balance=" + balance + ", version=" + version + "}";
    }
}
