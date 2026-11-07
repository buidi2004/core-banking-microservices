package com.fintech.payment.dto.dispute;

import jakarta.validation.constraints.NotBlank;

public record AssignDisputeRequest(
        @NotBlank(message = "assigneeId is required")
        String assigneeId,

        String note
) {}

