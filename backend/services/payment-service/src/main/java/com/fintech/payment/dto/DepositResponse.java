package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DepositResponse {
    private String transactionId;
    private String transactionCode;
    private String walletId;
    private Long amount;
    private Long balanceAfter;
    private String currency;
    private String status;
    private String message;
}

