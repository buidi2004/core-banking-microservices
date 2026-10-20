package com.fintech.payment.dto;

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
public class OpenSavingsRequest {
    @NotBlank
    private String walletId;

    @NotBlank
    private String productType;

    @NotNull
    private Integer termMonths;

    @NotNull
    @DecimalMin("100000")
    private BigDecimal depositAmount;

    @Builder.Default
    private String rolloverType = "AUTO_ROLLOVER_ALL";

    private String pinToken;
}

