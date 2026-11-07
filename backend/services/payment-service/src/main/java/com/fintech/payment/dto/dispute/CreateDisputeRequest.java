package com.fintech.payment.dto.dispute;

import jakarta.validation.constraints.NotBlank;

public record CreateDisputeRequest(
        @NotBlank(message = "transactionId is required")
        String transactionId,

        String disputeType,

        @NotBlank(message = "reason is required")
        String reason,

        Long requestedAmount
) {}

