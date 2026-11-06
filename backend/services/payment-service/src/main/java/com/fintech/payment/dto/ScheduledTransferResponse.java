package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledTransferResponse {
    private String id;
    private String sourceUserId;
    private String targetUserId;
    private String targetPhoneNumber;
    private String targetCustomerName;
    private Long amount;
    private String currency;
    private String note;
    private String frequency;
    private Integer dayOfMonth;
    private Instant nextExecutionAt;
    private String status;
    private Instant lastExecutedAt;
    private String lastTransactionId;
    private String failureReason;
    private Instant createdAt;
}

