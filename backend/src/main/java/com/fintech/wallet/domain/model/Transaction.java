package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: Transaction
 * Pure Java - No Spring / JPA annotations.
 */
public class Transaction {
    private final String id;
    private final String requestId;
    private final String sourceWalletId;
    private final String targetWalletId;
    private final Money amount;
    private final TransactionType type;
    private TransactionStatus status;
    private final Instant createdAt;
    private final String originalTransactionId;
    private final String note;
    private String bankCode;
    private Money feeAmount;
    private Money balanceAfter;

    public Transaction(String id, String requestId, String sourceWalletId, String targetWalletId, Money amount, TransactionType type, TransactionStatus status, Instant createdAt) {
        this(id, requestId, sourceWalletId, targetWalletId, amount, type, status, createdAt, null, null);
    }

    public Transaction(String id, String requestId, String sourceWalletId, String targetWalletId, Money amount, TransactionType type, TransactionStatus status, Instant createdAt, String originalTransactionId, String note) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.requestId = requestId;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.type = type;
        this.status = status != null ? status : TransactionStatus.PENDING;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.originalTransactionId = originalTransactionId;
        this.note = note;
    }

    public Transaction(String id, String sourceWalletId, String targetWalletId, Money amount, TransactionType type, TransactionStatus status, Instant createdAt) {
        this(id, null, sourceWalletId, targetWalletId, amount, type, status, createdAt);
    }

    public static Transaction createTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount, String note) {
        return new Transaction(
            UUID.randomUUID().toString(),
            requestId,
            sourceWalletId,
            targetWalletId,
            amount,
            TransactionType.TRANSFER,
            TransactionStatus.PENDING_CONFIRMATION,
            Instant.now(),
            null,
            note
        );
    }

    public static Transaction createTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount) {
        return createTransfer(requestId, sourceWalletId, targetWalletId, amount, null);
    }

    public static Transaction createTransfer(String sourceWalletId, String targetWalletId, Money amount) {
        return createTransfer(null, sourceWalletId, targetWalletId, amount, null);
    }

    public static Transaction createDeposit(String requestId, String targetWalletId, Money amount) {
        return new Transaction(
            UUID.randomUUID().toString(),
            requestId,
            null,
            targetWalletId,
            amount,
            TransactionType.DEPOSIT,
            TransactionStatus.PENDING,
            Instant.now()
        );
    }

    public static Transaction createDeposit(String targetWalletId, Money amount) {
        return createDeposit(null, targetWalletId, amount);
    }

    public static Transaction createWithdrawal(String requestId, String sourceWalletId, Money amount) {
        return new Transaction(
            UUID.randomUUID().toString(),
            requestId,
            sourceWalletId,
            null,
            amount,
            TransactionType.WITHDRAWAL,
            TransactionStatus.PENDING,
            Instant.now()
        );
    }

    public void markSuccess() {
        this.status = TransactionStatus.SUCCESS;
    }

    public void markFailed() {
        this.status = TransactionStatus.FAILED;
    }

    // SEC-3 fix: removed public setStatus() — status changes must go through
    // markSuccess(), markFailed(), markReversed(), or markProcessing() to enforce business rules.

    public void markProcessing() {
        this.status = TransactionStatus.PROCESSING;
    }

    public void markReversed() {
        this.status = TransactionStatus.REVERSED;
    }

    public static Transaction createReversal(String originalTransactionId, String walletId, Money amount) {
        return new Transaction(
            UUID.randomUUID().toString(),
            null,
            null,
            walletId,
            amount,
            TransactionType.REVERSAL,
            TransactionStatus.PENDING,
            Instant.now(),
            originalTransactionId,
            null
        );
    }

    public String getId() {
        return id;
    }

    public String getRequestId() {
        return requestId;
    }

    public String getSourceWalletId() {
        return sourceWalletId;
    }

    public String getTargetWalletId() {
        return targetWalletId;
    }

    public Money getAmount() {
        return amount;
    }

    public TransactionType getType() {
        return type;
    }

    public TransactionStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public String getOriginalTransactionId() {
        return originalTransactionId;
    }

    public String getNote() {
        return note;
    }

    public String getBankCode() {
        return bankCode;
    }

    public void setBankCode(String bankCode) {
        this.bankCode = bankCode;
    }

    public Money getFeeAmount() {
        return feeAmount;
    }

    public void setFeeAmount(Money feeAmount) {
        this.feeAmount = feeAmount;
    }

    public Money getBalanceAfter() {
        return balanceAfter;
    }

    public void setBalanceAfter(Money balanceAfter) {
        this.balanceAfter = balanceAfter;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Transaction that = (Transaction) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "Transaction{id='" + id + "', requestId='" + requestId + "', type=" + type + ", status=" + status + ", amount=" + amount + ", originalTransactionId='" + originalTransactionId + "'}";
    }
}
