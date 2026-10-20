package com.fintech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VietQrGenerateRequest {
    @NotBlank(message = "Mã định danh ngân hàng (BIN) không được để trống")
    private String bankBin;

    @NotBlank(message = "Số tài khoản thụ hưởng không được để trống")
    private String accountNumber;

    private BigDecimal amount;

    private String purpose;
}

