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
public class CardDto {
    private String id;
    private String type;         // "credit", "debit", "virtual"
    private String title;        // "SEN HỒNG VISA SIGNATURE"
    private String tier;         // "THẺ TÍN DỤNG QUỐC TẾ"
    private String scheme;       // "VISA", "NAPAS"
    private String number;       // full 16 digits
    private String maskedNumber; // •••• •••• •••• 6688
    private String holder;       // CHỦ THẺ SEN HỒNG
    private String expiry;       // "12/29"
    private String cvv;          // "889"
    private BigDecimal limit;
    private BigDecimal available;
    private String colorScheme;  // "platinum", "napas", "virtual"
    private boolean useAsset;
    private String status;       // "ACTIVE", "LOCKED", "BLOCKED"
    private boolean onlinePayment;
    private boolean intlPayment;
    private boolean contactless;
    private boolean atmWithdraw;
    private boolean physical;
}

