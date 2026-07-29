package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class Merchant {
    private final String id;
    private final String merchantName;
    private final String bankAccount;
    private final String secretKey;
    private String status;
    private final Instant createdAt;

    public Merchant(String id, String merchantName, String bankAccount, String secretKey, String status, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.merchantName = merchantName;
        this.bankAccount = bankAccount;
        this.secretKey = secretKey != null ? secretKey : UUID.randomUUID().toString().replace("-", "");
        this.status = status != null ? status : "ACTIVE";
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static Merchant createNew(String merchantName, String bankAccount) {
        return new Merchant(UUID.randomUUID().toString(), merchantName, bankAccount, UUID.randomUUID().toString().replace("-", ""), "ACTIVE", Instant.now());
    }

    public String getId() { return id; }
    public String getMerchantName() { return merchantName; }
    public String getBankAccount() { return bankAccount; }
    public String getSecretKey() { return secretKey; }
    public String getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
}
