package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchTransferItemResult {
    private String accountNumber;
    private String recipientName;
    private Long amount;
    private String status;
    private String transactionId;
    private String errorMessage;
}

