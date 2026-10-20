package com.fintech.payment.dto;

import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransferResponse {
    private String transactionId;
    private String transactionCode;
    private String sourceWalletId;
    private String targetWalletId;
    private String status;
    private Long amount;
    private String currency;

    public static TransferResponse from(com.fintech.payment.saga.SagaContext ctx) {
        return TransferResponse.builder()
                .transactionId(ctx.getTransactionId())
                .transactionCode(ctx.getTransactionCode())
                .sourceWalletId(ctx.getSourceWalletId())
                .targetWalletId(ctx.getTargetWalletId())
                .status(ctx.getStatus())
                .amount(ctx.getAmount())
                .currency(ctx.getCurrency())
                .build();
    }
}
