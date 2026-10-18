package com.fintech.notification.notification;

import java.math.BigDecimal;

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
    private final String note;
    private final String title;
    private final String body;

    public NotificationPayload(String transactionId, String requestId, String type, String status,
                               String walletId, BigDecimal transactionAmount, String transactionCurrency,
                               BigDecimal newBalance, String currency, String timestamp, String note,
                               String title, String body) {
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
        this.note = note;
        this.title = title;
        this.body = body;
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
    public String getNote() { return note; }
    public String getTitle() { return title; }
    public String getBody() { return body; }

    @Override
    public String toString() {
        return "NotificationPayload{txId='" + transactionId + "', walletId='" + walletId
                + "', type='" + type + "', status='" + status + "'}";
    }
}
