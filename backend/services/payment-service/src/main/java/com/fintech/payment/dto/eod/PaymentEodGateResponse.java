package com.fintech.payment.dto.eod;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentEodGateResponse {
    private boolean canCloseEod;
    private String gateStatus; // "CLEARED" | "BLOCKED"
    private long pendingCashDeposits;
    private long pendingCitTransfers;
    private long pendingDisputes;
    private long pendingAmlCases;
    private long pendingMakerCheckerTotal;
    private long pendingOutboxCount;
    private long failedOutboxCount;
    private List<String> blockingReasons;
}
