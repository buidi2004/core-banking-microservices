package com.fintech.payment.dto;

import lombok.*;

/**
 * DTO tổng kết quỹ tiền mặt trong ngày tại quầy giao dịch (Vault Summary).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultSummaryResponse {
    private long openingBalance;
    private long totalCashIn;
    private long currentBalance;
    private long maxLimit;
    private long successCount;
    private long pendingCount;
}
