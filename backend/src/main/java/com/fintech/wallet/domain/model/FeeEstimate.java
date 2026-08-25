package com.fintech.wallet.domain.model;

import java.math.BigDecimal;

/**
 * Domain Value Object: FeeEstimate
 * Represents the estimated fee for a transaction before the user confirms.
 * Displayed on the confirmation screen so the user knows the total cost.
 */
public class FeeEstimate {

    private final TransactionType transactionType;
    private final BigDecimal originalAmount;
    private final BigDecimal feeAmount;
    private final BigDecimal totalAmount;
    private final String currency;
    private final String feeWaivedReason;   // non-null if fee is waived (e.g. "P2P transfer is free")

    public FeeEstimate(TransactionType transactionType, BigDecimal originalAmount,
                       BigDecimal feeAmount, BigDecimal totalAmount,
                       String currency, String feeWaivedReason) {
        this.transactionType = transactionType;
        this.originalAmount = originalAmount;
        this.feeAmount = feeAmount;
        this.totalAmount = totalAmount;
        this.currency = currency;
        this.feeWaivedReason = feeWaivedReason;
    }

    public static FeeEstimate free(TransactionType type, BigDecimal amount, String currency, String reason) {
        return new FeeEstimate(type, amount, BigDecimal.ZERO, amount, currency, reason);
    }

    public static FeeEstimate withFee(TransactionType type, BigDecimal amount,
                                      BigDecimal fee, String currency) {
        return new FeeEstimate(type, amount, fee, amount.add(fee), currency, null);
    }

    public boolean isFeeWaived() {
        return feeWaivedReason != null;
    }

    public TransactionType getTransactionType() { return transactionType; }
    public BigDecimal getOriginalAmount()       { return originalAmount; }
    public BigDecimal getFeeAmount()            { return feeAmount; }
    public BigDecimal getTotalAmount()          { return totalAmount; }
    public String getCurrency()                 { return currency; }
    public String getFeeWaivedReason()          { return feeWaivedReason; }
}
