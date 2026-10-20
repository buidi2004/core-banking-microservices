package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavingsAccountResponse {
    private String id;
    private String userId;
    private String walletId;
    private String accountNumber;
    private String productType;
    private String productName;
    private BigDecimal principal;
    private BigDecimal interestRate;
    private int termMonths;
    private BigDecimal expectedInterest;
    private BigDecimal accruedInterest;
    private String rolloverType;
    private String status;
    private LocalDate startDate;
    private LocalDate maturityDate;
}

