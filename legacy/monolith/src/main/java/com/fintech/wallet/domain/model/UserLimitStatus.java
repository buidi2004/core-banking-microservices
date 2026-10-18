package com.fintech.wallet.domain.model;

import java.math.BigDecimal;

/**
 * Domain Value Object: UserLimitStatus
 * Returns the user's actual spent amounts alongside their configured limits,
 * so the frontend can display remaining capacity and warn before exceeding limits.
 */
public class UserLimitStatus {

    private final KycStatus kycStatus;
    private final BigDecimal dailyLimit;
    private final BigDecimal dailySpent;
    private final BigDecimal dailyRemaining;
    private final BigDecimal monthlyLimit;
    private final BigDecimal monthlySpent;
    private final BigDecimal monthlyRemaining;
    private final String currency;

    public UserLimitStatus(KycStatus kycStatus,
                           BigDecimal dailyLimit, BigDecimal dailySpent,
                           BigDecimal monthlyLimit, BigDecimal monthlySpent,
                           String currency) {
        this.kycStatus = kycStatus;
        this.dailyLimit = dailyLimit;
        this.dailySpent = dailySpent;
        this.dailyRemaining = dailyLimit.subtract(dailySpent).max(BigDecimal.ZERO);
        this.monthlyLimit = monthlyLimit;
        this.monthlySpent = monthlySpent;
        this.monthlyRemaining = monthlyLimit.subtract(monthlySpent).max(BigDecimal.ZERO);
        this.currency = currency;
    }

    public KycStatus getKycStatus()         { return kycStatus; }
    public BigDecimal getDailyLimit()        { return dailyLimit; }
    public BigDecimal getDailySpent()        { return dailySpent; }
    public BigDecimal getDailyRemaining()    { return dailyRemaining; }
    public BigDecimal getMonthlyLimit()      { return monthlyLimit; }
    public BigDecimal getMonthlySpent()      { return monthlySpent; }
    public BigDecimal getMonthlyRemaining()  { return monthlyRemaining; }
    public String getCurrency()              { return currency; }
}
