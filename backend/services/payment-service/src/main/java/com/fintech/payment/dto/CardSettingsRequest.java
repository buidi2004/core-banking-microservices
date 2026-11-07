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
public class CardSettingsRequest {
    private Boolean onlinePayment;
    private Boolean intlPayment;
    private Boolean contactless;
    private Boolean atmWithdraw;
    private BigDecimal limit;
}

