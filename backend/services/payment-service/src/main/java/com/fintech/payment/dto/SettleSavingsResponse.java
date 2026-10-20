package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettleSavingsResponse {
    private String accountNumber;
    private boolean earlySettlement;
    private BigDecimal principalReturned;
    private BigDecimal interestEarned;
    private BigDecimal totalPayout;
    private String creditedToWallet;
    private String message;
}

