package com.fintech.wallet.domain.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class MerchantOrder {
    private final String id;
    private final String merchantId;
    private final String orderRef;
    private final BigDecimal amount;
    private final String currency;
    private String status; // PENDING, PAID, FAILED, CANCELLED
    private final String callbackUrl;
    private final Instant createdAt;

    public MerchantOrder(String id, String merchantId, String orderRef, BigDecimal amount, String currency, String status, String callbackUrl, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.merchantId = merchantId;
        this.orderRef = orderRef;
        this.amount = amount;
        this.currency = currency != null ? currency : "VND";
        this.status = status != null ? status : "PENDING";
        this.callbackUrl = callbackUrl;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static MerchantOrder createNew(String merchantId, String orderRef, BigDecimal amount, String currency, String callbackUrl) {
        return new MerchantOrder(UUID.randomUUID().toString(), merchantId, orderRef, amount, currency, "PENDING", callbackUrl, Instant.now());
    }

    public void markPaid() {
        this.status = "PAID";
    }

    public String getId() { return id; }
    public String getMerchantId() { return merchantId; }
    public String getOrderRef() { return orderRef; }
    public BigDecimal getAmount() { return amount; }
    public String getCurrency() { return currency; }
    public String getStatus() { return status; }
    public String getCallbackUrl() { return callbackUrl; }
    public Instant getCreatedAt() { return createdAt; }
}
