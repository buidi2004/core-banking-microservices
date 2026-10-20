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
public class LoanRepaymentResponse {
    private String contractNumber;
    private int termNumber;
    private BigDecimal paidAmount;
    private BigDecimal remainingPrincipal;
    private String status;
    private boolean isFullyRepaid;
    private String message;
}

