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

    public Transaction(String id, String requestId, String sourceWalletId, String targetWalletId, Money amount, TransactionType type, TransactionStatus status, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.requestId = requestId;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.type = type;
        this.status = status != null ? status : TransactionStatus.PENDING;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public Transaction(String id, String sourceWalletId, String targetWalletId, Money amount, TransactionType type, TransactionStatus status, Instant createdAt) {
        this(id, null, sourceWalletId, targetWalletId, amount, type, status, createdAt);
    }

    public static Transaction createTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount) {
        return new Transaction(
            UUID.randomUUID().toString(),
            requestId,
            sourceWalletId,
            targetWalletId,
            amount,
            TransactionType.TRANSFER,
            TransactionStatus.PENDING,
            Instant.now()
        );
    }

    public static Transaction createTransfer(String sourceWalletId, String targetWalletId, Money amount) {
        return createTransfer(null, sourceWalletId, targetWalletId, amount);
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
        return "Transaction{id='" + id + "', requestId='" + requestId + "', type=" + type + ", status=" + status + ", amount=" + amount + "}";
    }
}
