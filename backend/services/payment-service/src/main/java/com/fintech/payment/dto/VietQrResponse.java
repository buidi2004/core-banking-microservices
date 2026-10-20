package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VietQrResponse {
    private String qrRaw;
    private String qrDataUrl;
    private String bankBin;
    private String accountNumber;
    private BigDecimal amount;
    private String purpose;
}

