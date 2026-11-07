package com.fintech.payment.dto.dispute;

import jakarta.validation.constraints.NotBlank;

public record ResolveDisputeRequest(
        @NotBlank(message = "action is required (REFUND or REJECT)")
        String action,

        @NotBlank(message = "resolutionNote is required")
        String resolutionNote
) {}

