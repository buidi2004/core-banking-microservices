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
public class BillPaymentResponse {
    private String transactionId;
    private String billId;
    private String status;
    private BigDecimal amount;
    private String message;

    public String getTransactionCode() {
        return transactionId != null ? "TX-" + transactionId.substring(0, Math.min(8, transactionId.length())).toUpperCase() : null;
    }
}

