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
public class LoanApplicationResponse {
    private String id;
    private String contractNumber;
    private String userId;
    private String walletId;
    private String productType;
    private String productName;
    private BigDecimal principalAmount;
    private BigDecimal annualInterestRate;
    private int termMonths;
    private BigDecimal totalInterest;
    private BigDecimal totalRepayment;
    private BigDecimal monthlyPayment;
    private String status;
    private String disbursedAt;
    private String firstDueDate;
}

