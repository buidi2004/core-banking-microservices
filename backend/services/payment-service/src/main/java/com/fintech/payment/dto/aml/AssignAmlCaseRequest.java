package com.fintech.payment.dto.aml;

import jakarta.validation.constraints.NotBlank;

public record AssignAmlCaseRequest(
        @NotBlank String assigneeId,
        @NotBlank String reason
) {
}
