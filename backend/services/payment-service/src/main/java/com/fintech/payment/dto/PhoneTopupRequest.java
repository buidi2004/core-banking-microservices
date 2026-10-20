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
public class PhoneTopupRequest {
    private String requestId;

    @NotBlank(message = "walletId không được để trống")
    private String walletId;

    @NotBlank(message = "phoneNumber không được để trống")
    private String phoneNumber;

    @NotNull(message = "amount không được để trống")
    @DecimalMin(value = "10000", message = "Mệnh giá nạp tối thiểu là 10,000 VND")
    private BigDecimal amount;

    private String currency;
    private String pinToken;
}

