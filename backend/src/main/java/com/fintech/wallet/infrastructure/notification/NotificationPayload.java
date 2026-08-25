package com.fintech.wallet.infrastructure.notification;

import java.math.BigDecimal;

/**
 * Type-safe DTO for WebSocket notification payloads.
 * Replaces raw HashMap to prevent key name typos and provide compile-time safety.
 */
public class NotificationPayload {

    private final String transactionId;
    private final String requestId;
    private final String type;
    private final String status;
    private final String walletId;
    private final BigDecimal transactionAmount;
    private final String transactionCurrency;
    private final BigDecimal newBalance;
    private final String currency;
    private final String timestamp;

    public NotificationPayload(String transactionId, String requestId, String type, String status,
                               String walletId, BigDecimal transactionAmount, String transactionCurrency,
                               BigDecimal newBalance, String currency, String timestamp) {
        this.transactionId = transactionId;
        this.requestId = requestId;
        this.type = type;
        this.status = status;
        this.walletId = walletId;
        this.transactionAmount = transactionAmount;
        this.transactionCurrency = transactionCurrency;
        this.newBalance = newBalance;
        this.currency = currency;
        this.timestamp = timestamp;
    }

    public String getTransactionId() { return transactionId; }
    public String getRequestId() { return requestId; }
    public String getType() { return type; }
    public String getStatus() { return status; }
    public String getWalletId() { return walletId; }
    public BigDecimal getTransactionAmount() { return transactionAmount; }
    public String getTransactionCurrency() { return transactionCurrency; }
    public BigDecimal getNewBalance() { return newBalance; }
    public String getCurrency() { return currency; }
    public String getTimestamp() { return timestamp; }

    @Override
    public String toString() {
        return "NotificationPayload{txId='" + transactionId + "', walletId='" + walletId +
                "', type='" + type + "', status='" + status + "'}";
    }
}
