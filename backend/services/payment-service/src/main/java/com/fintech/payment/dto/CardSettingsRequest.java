package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardSettingsRequest {
    private Boolean onlinePayment;
    private Boolean intlPayment;
    private Boolean contactless;
    private Boolean atmWithdraw;
}

