package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TransferRequest {

    private String requestId;

    @NotBlank(message = "Source wallet ID is required")
    private String sourceWalletId;

    @NotBlank(message = "Target wallet ID is required")
    private String targetWalletId;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Transfer amount must be greater than zero")
    private BigDecimal amount;

    @NotBlank(message = "Currency is required")
    private String currency;
}
