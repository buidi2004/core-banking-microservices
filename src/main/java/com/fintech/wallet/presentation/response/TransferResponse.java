package com.fintech.wallet.presentation.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fintech.wallet.domain.model.Transaction;

import java.math.BigDecimal;
import java.time.Instant;

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
    private String originalTransactionId;

    public static TransferResponse fromDomain(Transaction transaction) {
        if (transaction == null) return null;
        TransferResponse resp = new TransferResponse(
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
        resp.setOriginalTransactionId(transaction.getOriginalTransactionId());
        return resp;
    }

    public String getTransactionId() {
        return transactionId;
    }
    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public String getRequestId() {
        return requestId;
    }
    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getSourceWalletId() {
        return sourceWalletId;
    }
    public void setSourceWalletId(String sourceWalletId) {
        this.sourceWalletId = sourceWalletId;
    }

    public String getTargetWalletId() {
        return targetWalletId;
    }
    public void setTargetWalletId(String targetWalletId) {
        this.targetWalletId = targetWalletId;
    }

    public BigDecimal getAmount() {
        return amount;
    }
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getType() {
        return type;
    }
    public void setType(String type) {
        this.type = type;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getTimestamp() {
        return timestamp;
    }
    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }

    public String getOriginalTransactionId() {
        return originalTransactionId;
    }
    public void setOriginalTransactionId(String originalTransactionId) {
        this.originalTransactionId = originalTransactionId;
    }

    public TransferResponse() {}

    public TransferResponse(String transactionId, String requestId, String sourceWalletId, String targetWalletId, BigDecimal amount, String currency, String type, String status, Instant timestamp) {
        this.transactionId = transactionId;
        this.requestId = requestId;
        this.sourceWalletId = sourceWalletId;
        this.targetWalletId = targetWalletId;
        this.amount = amount;
        this.currency = currency;
        this.type = type;
        this.status = status;
        this.timestamp = timestamp;
    }
}
