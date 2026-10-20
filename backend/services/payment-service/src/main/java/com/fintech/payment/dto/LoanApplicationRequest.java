package com.fintech.payment.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoanApplicationRequest {
    @NotBlank
    private String walletId;

    @NotBlank
    private String productType;

    @NotNull
    @DecimalMin("5000000")
    @DecimalMax("50000000")
    private BigDecimal amount;

    @NotNull
    private Integer termMonths;

    private String purpose;

    private String pinToken;
}

