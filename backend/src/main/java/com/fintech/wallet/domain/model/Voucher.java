package com.fintech.wallet.domain.model;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class Voucher {
    private final String id;
    private final String code;
    private final String title;
    private final BigDecimal discountAmount;
    private final BigDecimal minOrderAmount;
    private final Instant expiryDate;
    private String status; // ACTIVE, REDEEMED, EXPIRED

    public Voucher(String id, String code, String title, BigDecimal discountAmount, BigDecimal minOrderAmount, Instant expiryDate, String status) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.code = code;
        this.title = title;
        this.discountAmount = discountAmount;
        this.minOrderAmount = minOrderAmount != null ? minOrderAmount : BigDecimal.ZERO;
        this.expiryDate = expiryDate;
        this.status = status != null ? status : "ACTIVE";
    }

    public static Voucher createNew(String code, String title, BigDecimal discountAmount, BigDecimal minOrderAmount, Instant expiryDate) {
        return new Voucher(UUID.randomUUID().toString(), code, title, discountAmount, minOrderAmount, expiryDate, "ACTIVE");
    }

    public void redeem() {
        this.status = "REDEEMED";
    }

    public String getId() { return id; }
    public String getCode() { return code; }
    public String getTitle() { return title; }
    public BigDecimal getDiscountAmount() { return discountAmount; }
    public BigDecimal getMinOrderAmount() { return minOrderAmount; }
    public Instant getExpiryDate() { return expiryDate; }
    public String getStatus() { return status; }
}
