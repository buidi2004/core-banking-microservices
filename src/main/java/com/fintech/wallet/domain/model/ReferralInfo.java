package com.fintech.wallet.domain.model;

import java.math.BigDecimal;

public class ReferralInfo {
    private final String userId;
    private final String referralCode;
    private final BigDecimal totalEarned;
    private final int invitedCount;

    public ReferralInfo(String userId, String referralCode, BigDecimal totalEarned, int invitedCount) {
        this.userId = userId;
        this.referralCode = referralCode;
        this.totalEarned = totalEarned != null ? totalEarned : BigDecimal.ZERO;
        this.invitedCount = invitedCount;
    }

    public String getUserId() { return userId; }
    public String getReferralCode() { return referralCode; }
    public BigDecimal getTotalEarned() { return totalEarned; }
    public int getInvitedCount() { return invitedCount; }
}
