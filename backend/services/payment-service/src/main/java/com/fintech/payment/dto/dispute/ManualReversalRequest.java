package com.fintech.payment.dto.dispute;

import jakarta.validation.constraints.NotBlank;

public record ManualReversalRequest(
        @NotBlank(message = "reason is required")
        String reason
) {}

