package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "beneficiaries")
public class BeneficiaryJpaEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String userId;

    private String beneficiaryWalletId;
    private String nickname;
    private String bankCode;
    private String accountNumber;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    public BeneficiaryJpaEntity() {}

    public BeneficiaryJpaEntity(String id, String userId, String beneficiaryWalletId, String nickname, String bankCode, String accountNumber, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.beneficiaryWalletId = beneficiaryWalletId;
        this.nickname = nickname;
        this.bankCode = bankCode;
        this.accountNumber = accountNumber;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getBeneficiaryWalletId() { return beneficiaryWalletId; }
    public void setBeneficiaryWalletId(String beneficiaryWalletId) { this.beneficiaryWalletId = beneficiaryWalletId; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
