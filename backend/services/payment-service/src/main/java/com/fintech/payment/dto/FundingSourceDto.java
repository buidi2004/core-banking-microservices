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
public class FundingSourceDto {
    private String id;
    private String sourceType;    // WALLET, LINKED_BANK, CREDIT_CARD
    private String sourceRefId;
    private String title;
    private String subtitle;
    private BigDecimal balanceOrLimit;
    private boolean active;
    private int priority;
}

