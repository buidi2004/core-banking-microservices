package com.fintech.payment.grpc.dto;

import lombok.*;

/**
 * Kết quả gọi gRPC CheckLimit.
 */
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class WalletLimitResult {
    private boolean allowed;
    private Long availableBalance;
    private Long dailyLimitRemaining;
    private Long transactionLimitRemaining;
    private String errorCode;
    private String errorMessage;
}
