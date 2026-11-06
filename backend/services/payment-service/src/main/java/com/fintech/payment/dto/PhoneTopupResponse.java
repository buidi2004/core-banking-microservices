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
public class PhoneTopupResponse {
    private String transactionId;
    private String phoneNumber;
    private BigDecimal amount;
    private BigDecimal discountAmount;
    private BigDecimal netAmount;
    private String status;
    private String message;

    public String getTransactionCode() {
        return transactionId != null ? "TX-" + transactionId.substring(0, Math.min(8, transactionId.length())).toUpperCase() : null;
    }
}

