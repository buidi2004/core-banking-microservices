package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.FeeEstimate;

import java.math.BigDecimal;

/**
 * Response DTO for fee estimation endpoint.
 * Maps domain FeeEstimate to a client-friendly format.
 */
public class FeeEstimateResponse {

    private final String transactionType;
    private final BigDecimal originalAmount;
    private final BigDecimal feeAmount;
    private final BigDecimal totalAmount;
    private final String currency;
    private final boolean feeWaived;
    private final String feeWaivedReason;

    public FeeEstimateResponse(String transactionType, BigDecimal originalAmount,
                               BigDecimal feeAmount, BigDecimal totalAmount,
                               String currency, boolean feeWaived, String feeWaivedReason) {
        this.transactionType = transactionType;
        this.originalAmount = originalAmount;
        this.feeAmount = feeAmount;
        this.totalAmount = totalAmount;
        this.currency = currency;
        this.feeWaived = feeWaived;
        this.feeWaivedReason = feeWaivedReason;
    }

    public static FeeEstimateResponse fromDomain(FeeEstimate estimate) {
        return new FeeEstimateResponse(
                estimate.getTransactionType().name(),
                estimate.getOriginalAmount(),
                estimate.getFeeAmount(),
                estimate.getTotalAmount(),
                estimate.getCurrency(),
                estimate.isFeeWaived(),
                estimate.getFeeWaivedReason()
        );
    }

    public String getTransactionType()     { return transactionType; }
    public BigDecimal getOriginalAmount()   { return originalAmount; }
    public BigDecimal getFeeAmount()        { return feeAmount; }
    public BigDecimal getTotalAmount()      { return totalAmount; }
    public String getCurrency()             { return currency; }
    public boolean isFeeWaived()            { return feeWaived; }
    public String getFeeWaivedReason()      { return feeWaivedReason; }
}
