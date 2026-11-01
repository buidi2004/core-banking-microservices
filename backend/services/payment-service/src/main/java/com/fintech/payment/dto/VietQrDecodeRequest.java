package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VietQrDecodeRequest {
    private String qrString;
    private String qrText;

    public String getQrString() {
        if (qrString != null && !qrString.isBlank()) {
            return qrString;
        }
        return qrText;
    }
}

