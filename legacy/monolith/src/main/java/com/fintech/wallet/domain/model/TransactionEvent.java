package com.fintech.wallet.domain.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class TransactionEvent {
    private String eventId;
    private String transactionId;
    private String type;
    private String status;
    private String sourceWalletId;
    private String targetWalletId;
    private BigDecimal amount;
    private String currency;
    private Instant occurredAt;

    public TransactionEvent() {
    }

    public TransactionEvent(String transactionId, String type, String status, String sourceWalletId, String targetWalletId, BigDecimal amount, String currency) {
        this.eventId = UUID.randomUUID().toString();
        this.transactionId = transactionId;
        this.type = type;
        this.status = status;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.currency = currency;
        this.occurredAt = Instant.now();
    }
    
    // Used for deserialization
    public TransactionEvent(String eventId, String transactionId, String type, String status, String sourceWalletId, String targetWalletId, BigDecimal amount, String currency, Instant occurredAt) {
        this.eventId = eventId;
        this.transactionId = transactionId;
        this.type = type;
        this.status = status;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.currency = currency;
        this.occurredAt = occurredAt;
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
}
