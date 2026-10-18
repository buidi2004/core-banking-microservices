package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_transaction_request_id", columnList = "request_id", unique = true)
})
public class TransactionJpaEntity {

    @Id
    private String id;

    @Column(name = "request_id")
    private String requestId;

    @Column(name = "source_wallet_id")
    private String sourceWalletId;

    @Column(name = "target_wallet_id")
    private String targetWalletId;

    @Column(name = "amount", nullable = false)
    private BigDecimal amount;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "type", nullable = false)
    private String type;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "note")
    private String note;

    @Column(name = "bank_code")
    private String bankCode;

    @Column(name = "fee_amount")
    private BigDecimal feeAmount;

    @Column(name = "balance_after")
    private BigDecimal balanceAfter;

    @Column(name = "receiver_balance_after")
    private BigDecimal receiverBalanceAfter;

    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }

    public String getRequestId() {
        return requestId;
    }
    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getSourceWalletId() {
        return sourceWalletId;
    }
    public void setSourceWalletId(String sourceWalletId) {
        this.sourceWalletId = sourceWalletId;
    }

    public String getTargetWalletId() {
        return targetWalletId;
    }
    public void setTargetWalletId(String targetWalletId) {
        this.targetWalletId = targetWalletId;
    }

    public BigDecimal getAmount() {
        return amount;
    }
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getType() {
        return type;
    }
    public void setType(String type) {
        this.type = type;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public String getNote() {
        return note;
    }
    public void setNote(String note) {
        this.note = note;
    }

    public String getBankCode() {
        return bankCode;
    }
    public void setBankCode(String bankCode) {
        this.bankCode = bankCode;
    }

    public BigDecimal getFeeAmount() {
        return feeAmount;
    }
    public void setFeeAmount(BigDecimal feeAmount) {
        this.feeAmount = feeAmount;
    }

    public BigDecimal getBalanceAfter() {
        return balanceAfter;
    }
    public void setBalanceAfter(BigDecimal balanceAfter) {
        this.balanceAfter = balanceAfter;
    }

    public BigDecimal getReceiverBalanceAfter() {
        return receiverBalanceAfter;
    }
    public void setReceiverBalanceAfter(BigDecimal receiverBalanceAfter) {
        this.receiverBalanceAfter = receiverBalanceAfter;
    }

    public TransactionJpaEntity() {}

    public TransactionJpaEntity(String id, String requestId, String sourceWalletId, String targetWalletId, BigDecimal amount, String currency, String type, String status, Instant createdAt, String note) {
        this.id = id;
        this.requestId = requestId;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.currency = currency;
        this.type = type;
        this.status = status;
        this.createdAt = createdAt;
        this.note = note;
    }
}
