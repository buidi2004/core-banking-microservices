package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavingsProductDto {
    private String productType;
    private String productName;
    private String description;
    private String badge;
    private BigDecimal minDeposit;
    private BigDecimal baseRate;
    private List<TermRateDto> terms;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TermRateDto {
        private int months;
        private BigDecimal rate;
        private String tag;
    }
}

