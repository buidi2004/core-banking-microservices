package com.fintech.payment.dto.aml;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record CreateAmlCaseRequest(
        @NotBlank String transactionId,
        String customerId,
        @NotBlank String reason,
        @Min(1) @Max(720) Integer slaHours
) {
}
