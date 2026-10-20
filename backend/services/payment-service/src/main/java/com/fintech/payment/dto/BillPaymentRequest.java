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
public class BillPaymentRequest {
    private String requestId;

    @NotBlank(message = "walletId không được để trống")
    private String walletId;

    @NotBlank(message = "billId không được để trống")
    private String billId;

    @NotNull(message = "amount không được để trống")
    @DecimalMin(value = "1000", message = "Số tiền tối thiểu là 1,000 VND")
    private BigDecimal amount;

    private String currency;
    private String pinToken;
}

