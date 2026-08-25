package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public class Beneficiary {
    private final String id;
    private final String userId;
    private final String beneficiaryWalletId;
    private final String nickname;
    private final String bankCode;
    private final String accountNumber;
    private final Instant createdAt;

    public Beneficiary(String id, String userId, String beneficiaryWalletId, String nickname, String bankCode, String accountNumber, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.beneficiaryWalletId = beneficiaryWalletId;
        this.nickname = nickname;
        this.bankCode = bankCode;
        this.accountNumber = accountNumber;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static Beneficiary createNew(String userId, String beneficiaryWalletId, String nickname, String bankCode, String accountNumber) {
        return new Beneficiary(
            UUID.randomUUID().toString(),
            userId,
            beneficiaryWalletId,
            nickname,
            bankCode,
            accountNumber,
            Instant.now()
        );
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getBeneficiaryWalletId() { return beneficiaryWalletId; }
    public String getNickname() { return nickname; }
    public String getBankCode() { return bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public Instant getCreatedAt() { return createdAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Beneficiary that = (Beneficiary) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() { return Objects.hash(id); }
}
