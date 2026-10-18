package com.fintech.payment.grpc.dto;

import lombok.*;

/**
 * Kết quả gọi gRPC DebitWallet / CreditWallet từ Wallet Service.
 */
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class WalletBalanceResult {
    private boolean success;
    private Long balanceAfter;
    private String errorCode;
    private String errorMessage;
}
