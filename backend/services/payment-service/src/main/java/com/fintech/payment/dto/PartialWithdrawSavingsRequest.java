package com.fintech.payment.dto;

import jakarta.validation.constraints.DecimalMin;
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
public class PartialWithdrawSavingsRequest {
    @NotNull(message = "Số tiền rút không được để trống")
    @DecimalMin(value = "100000", message = "Số tiền rút tối thiểu là 100.000 VND")
    private BigDecimal withdrawAmount;

    private String pinToken;
}

