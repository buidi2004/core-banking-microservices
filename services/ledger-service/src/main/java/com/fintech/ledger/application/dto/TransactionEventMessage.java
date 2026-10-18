package com.fintech.ledger.application.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Bản sao hợp đồng sự kiện TransactionEvent phát từ Monolith/Payment Service
 * lên exchange "wallet.transaction.events" (routing key "transaction.#").
 * Được consumer Ledger dùng để ghi bút toán kép Nợ/Có.
 */
public class TransactionEventMessage {

    private String eventId;
    private String transactionId;
    private String type;
    private String status;
    private String sourceWalletId;
    private String targetWalletId;
    private BigDecimal amount;
    private String currency;
    private Instant occurredAt;

    public TransactionEventMessage() {
    }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSourceWalletId() { return sourceWalletId; }
    public void setSourceWalletId(String sourceWalletId) { this.sourceWalletId = sourceWalletId; }

    public String getTargetWalletId() { return targetWalletId; }
    public void setTargetWalletId(String targetWalletId) { this.targetWalletId = targetWalletId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }

    public boolean isCompleted() {
        return "SUCCESS".equalsIgnoreCase(status) || "COMPLETED".equalsIgnoreCase(status);
    }

    public boolean isReversed() {
        return "REVERSED".equalsIgnoreCase(status) || "REVERSED".equalsIgnoreCase(type);
    }

    @Override
    public String toString() {
        return "TransactionEventMessage{eventId=" + eventId + ", transactionId=" + transactionId
                + ", type=" + type + ", status=" + status + "}";
    }
}
