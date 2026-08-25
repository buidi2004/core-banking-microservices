package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: MoneyRequest
 * Represents a P2P money request where one user asks another to send them money.
 * Similar to features in MoMo, ZaloPay where you can request payment from friends.
 */
public class MoneyRequest {
    private final String id;
    private final String requesterId;      // User who requests money
    private final String payerId;          // User who is asked to pay
    private final String requesterWalletId;
    private final String payerWalletId;
    private final Money amount;
    private final String message;          // Optional message: "Lunch money", "Split bill", etc.
    private MoneyRequestStatus status;
    private final Instant createdAt;
    private Instant updatedAt;
    private String transactionId;          // Set when request is fulfilled

    public MoneyRequest(String id, String requesterId, String payerId, 
                       String requesterWalletId, String payerWalletId,
                       Money amount, String message, MoneyRequestStatus status,
                       Instant createdAt, Instant updatedAt, String transactionId) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.requesterId = requesterId;
        this.payerId = payerId;
        this.requesterWalletId = requesterWalletId;
        this.payerWalletId = payerWalletId;
        this.amount = amount;
        this.message = message;
        this.status = status != null ? status : MoneyRequestStatus.PENDING;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
        this.transactionId = transactionId;
    }

    public static MoneyRequest create(String requesterId, String payerId,
                                     String requesterWalletId, String payerWalletId,
                                     Money amount, String message) {
        return new MoneyRequest(
            UUID.randomUUID().toString(),
            requesterId,
            payerId,
            requesterWalletId,
            payerWalletId,
            amount,
            message,
            MoneyRequestStatus.PENDING,
            Instant.now(),
            Instant.now(),
            null
        );
    }

    public void accept(String transactionId) {
        if (this.status != MoneyRequestStatus.PENDING) {
            throw new IllegalStateException("Money request is not in PENDING state");
        }
        this.status = MoneyRequestStatus.ACCEPTED;
        this.transactionId = transactionId;
        this.updatedAt = Instant.now();
    }

    public void reject() {
        if (this.status != MoneyRequestStatus.PENDING) {
            throw new IllegalStateException("Money request is not in PENDING state");
        }
        this.status = MoneyRequestStatus.REJECTED;
        this.updatedAt = Instant.now();
    }

    public void cancel() {
        if (this.status != MoneyRequestStatus.PENDING) {
            throw new IllegalStateException("Only PENDING requests can be cancelled");
        }
        this.status = MoneyRequestStatus.CANCELLED;
        this.updatedAt = Instant.now();
    }

    public void expire() {
        if (this.status == MoneyRequestStatus.PENDING) {
            this.status = MoneyRequestStatus.EXPIRED;
            this.updatedAt = Instant.now();
        }
    }

    public boolean isPending() {
        return this.status == MoneyRequestStatus.PENDING;
    }

    public boolean canBeCancelled() {
        return this.status == MoneyRequestStatus.PENDING;
    }

    public boolean canBeAcceptedOrRejected() {
        return this.status == MoneyRequestStatus.PENDING;
    }

    // Getters
    public String getId() { return id; }
    public String getRequesterId() { return requesterId; }
    public String getPayerId() { return payerId; }
    public String getRequesterWalletId() { return requesterWalletId; }
    public String getPayerWalletId() { return payerWalletId; }
    public Money getAmount() { return amount; }
    public String getMessage() { return message; }
    public MoneyRequestStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public String getTransactionId() { return transactionId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MoneyRequest that = (MoneyRequest) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "MoneyRequest{id='" + id + "', requesterId='" + requesterId + 
               "', payerId='" + payerId + "', amount=" + amount + 
               ", status=" + status + "}";
    }
}
