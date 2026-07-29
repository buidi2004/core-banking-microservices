package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "bank_accounts")
public class BankAccountJpaEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String userId;

    @Column(nullable = false)
    private String bankCode;

    @Column(nullable = false)
    private String accountNumber;

    @Column(nullable = false)
    private String accountHolderName;

    private boolean isDefault;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    public BankAccountJpaEntity() {}

    public BankAccountJpaEntity(String id, String userId, String bankCode, String accountNumber, String accountHolderName, boolean isDefault, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.bankCode = bankCode;
        this.accountNumber = accountNumber;
        this.accountHolderName = accountHolderName;
        this.isDefault = isDefault;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
    public String getAccountHolderName() { return accountHolderName; }
    public void setAccountHolderName(String accountHolderName) { this.accountHolderName = accountHolderName; }
    public boolean isDefault() { return isDefault; }
    public void setDefault(boolean aDefault) { isDefault = aDefault; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
