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

    // Các trường mở rộng chuẩn hóa cho thiết bị di động (Mobile HUD & push format)
    private final String accountNumber;
    private final String phoneNumber;
    private final BigDecimal amount;
    private final String formattedTime;

    /**
     * Constructor tương thích ngược 13 tham số.
     */
    public NotificationPayload(String transactionId, String requestId, String type, String status,
                               String walletId, BigDecimal transactionAmount, String transactionCurrency,
                               BigDecimal newBalance, String currency, String timestamp, String note,
                               String title, String body) {
        this(transactionId, requestId, type, status, walletId, transactionAmount, transactionCurrency,
                newBalance, currency, timestamp, note, title, body,
                walletId, null, transactionAmount, timestamp);
    }

    /**
     * Constructor đầy đủ 17 tham số hỗ trợ hiển thị tối ưu trên Mobile.
     */
    public NotificationPayload(String transactionId, String requestId, String type, String status,
                               String walletId, BigDecimal transactionAmount, String transactionCurrency,
                               BigDecimal newBalance, String currency, String timestamp, String note,
                               String title, String body,
                               String accountNumber, String phoneNumber, BigDecimal amount, String formattedTime) {
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
        this.accountNumber = accountNumber != null ? accountNumber : walletId;
        this.phoneNumber = phoneNumber;
        this.amount = amount != null ? amount : transactionAmount;
        this.formattedTime = formattedTime != null ? formattedTime : timestamp;
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

    public String getAccountNumber() { return accountNumber; }
    public String getPhoneNumber() { return phoneNumber; }
    public BigDecimal getAmount() { return amount; }
    public String getFormattedTime() { return formattedTime; }

    @Override
    public String toString() {
        return "NotificationPayload{txId='" + transactionId + "', walletId='" + walletId
                + "', type='" + type + "', status='" + status + "', account='" + accountNumber + "'}";
    }
}
