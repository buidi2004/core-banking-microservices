package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.Wallet;

import java.math.BigDecimal;
import java.time.Instant;

public class WalletResponse {

    private String id;
    private String ownerId;
    private BigDecimal balance;
    private String currency;
    private Instant createdAt;
    private Instant updatedAt;

    public static WalletResponse fromDomain(Wallet wallet) {
        if (wallet == null) return null;
        return new WalletResponse(
                wallet.getId(),
                wallet.getOwnerId(),
                wallet.getBalance().getAmount(),
                wallet.getBalance().getCurrency(),
                wallet.getCreatedAt(),
                wallet.getUpdatedAt()
        );
    }

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

    public BigDecimal getBalance() {
        return balance;
    }
    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
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

    public WalletResponse() {}

    public WalletResponse(String id, String ownerId, BigDecimal balance, String currency, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.ownerId = ownerId;
        this.balance = balance;
        this.currency = currency;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
