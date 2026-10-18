package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: BankAccount
 * Pure Java - No Spring / JPA annotations.
 */
public class BankAccount {
    private final String id;
    private final String userId;
    private final String bankCode;
    private final String accountNumber;
    private final String accountHolderName;
    private final boolean isDefault;
    private final Instant createdAt;

    public BankAccount(String id, String userId, String bankCode, String accountNumber, String accountHolderName, boolean isDefault, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.bankCode = bankCode;
        this.accountNumber = accountNumber;
        this.accountHolderName = accountHolderName;
        this.isDefault = isDefault;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static BankAccount createNew(String userId, String bankCode, String accountNumber, String accountHolderName, boolean isDefault) {
        return new BankAccount(
            UUID.randomUUID().toString(),
            userId,
            bankCode,
            accountNumber,
            accountHolderName,
            isDefault,
            Instant.now()
        );
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getBankCode() { return bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public String getAccountHolderName() { return accountHolderName; }
    public boolean isDefault() { return isDefault; }
    public Instant getCreatedAt() { return createdAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BankAccount account = (BankAccount) o;
        return Objects.equals(id, account.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
