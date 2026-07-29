package com.fintech.wallet.presentation.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fintech.wallet.domain.model.Transaction;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TransferResponse {

    private String transactionId;
    private String requestId;
    private String sourceWalletId;
    private String targetWalletId;
    private BigDecimal amount;
    private String currency;
    private String type;
    private String status;
    private Instant timestamp;

    public static TransferResponse fromDomain(Transaction transaction) {
        if (transaction == null) return null;
        return new TransferResponse(
                transaction.getId(),
                transaction.getRequestId(),
                transaction.getSourceWalletId(),
                transaction.getTargetWalletId(),
                transaction.getAmount().getAmount(),
                transaction.getAmount().getCurrency(),
                transaction.getType().name(),
                transaction.getStatus().name(),
                transaction.getCreatedAt()
        );
    }
}
