package com.fintech.payment.dto.aml;

import jakarta.validation.constraints.NotBlank;

public record UpdateAmlCaseStatusRequest(
        @NotBlank String status,
        @NotBlank String reason
) {
}
