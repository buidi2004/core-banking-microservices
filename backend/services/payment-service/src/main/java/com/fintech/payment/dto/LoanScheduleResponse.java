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
public class LoanScheduleResponse {
    private String contractNumber;
    private BigDecimal principalAmount;
    private int termMonths;
    private List<ScheduleItemDto> schedule;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ScheduleItemDto {
        private int termNumber;
        private String dueDate;
        private BigDecimal principalAmount;
        private BigDecimal interestAmount;
        private BigDecimal totalAmount;
        private BigDecimal remainingBalance;
        private String status;
        private String paidDate;
    }
}

