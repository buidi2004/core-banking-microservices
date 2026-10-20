package com.fintech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VietQrDecodeRequest {
    @NotBlank(message = "Chuỗi mã QR không được để trống")
    private String qrString;
}

