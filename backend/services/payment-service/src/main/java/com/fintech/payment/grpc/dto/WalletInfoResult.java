package com.fintech.payment.grpc.dto;

import lombok.*;

/**
 * Kết quả gọi gRPC GetWalletByUserId.
 */
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class WalletInfoResult {
    private boolean found;
    private String walletId;
    private String userId;
    private Long balance;
    private String currency;
    private String status;
    private String errorCode;
    private String errorMessage;
}
