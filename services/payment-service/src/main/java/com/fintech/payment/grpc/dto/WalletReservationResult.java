package com.fintech.payment.grpc.dto;

import lombok.*;

/**
 * Kết quả gọi gRPC ReserveBalance / ReleaseBalance.
 */
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class WalletReservationResult {
    private boolean success;
    private Long reservedAmount;
    private String reservationId;
    private String errorCode;
    private String errorMessage;
}
