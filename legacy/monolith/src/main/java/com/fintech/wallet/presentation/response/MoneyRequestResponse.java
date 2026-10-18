package com.fintech.wallet.presentation.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fintech.wallet.domain.model.MoneyRequest;

import java.math.BigDecimal;
import java.time.Instant;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class MoneyRequestResponse {

    private String id;
    private String requesterId;
    private String payerId;
    private String requesterWalletId;
    private String payerWalletId;
    private BigDecimal amount;
    private String currency;
    private String message;
    private String status;
    private Instant createdAt;
    private Instant updatedAt;
    private String transactionId;

    public static MoneyRequestResponse fromDomain(MoneyRequest moneyRequest) {
        if (moneyRequest == null) return null;
        
        MoneyRequestResponse response = new MoneyRequestResponse();
        response.id = moneyRequest.getId();
        response.requesterId = moneyRequest.getRequesterId();
        response.payerId = moneyRequest.getPayerId();
        response.requesterWalletId = moneyRequest.getRequesterWalletId();
        response.payerWalletId = moneyRequest.getPayerWalletId();
        response.amount = moneyRequest.getAmount().getAmount();
        response.currency = moneyRequest.getAmount().getCurrency();
        response.message = moneyRequest.getMessage();
        response.status = moneyRequest.getStatus().name();
        response.createdAt = moneyRequest.getCreatedAt();
        response.updatedAt = moneyRequest.getUpdatedAt();
        response.transactionId = moneyRequest.getTransactionId();
        return response;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRequesterId() {
        return requesterId;
    }

    public void setRequesterId(String requesterId) {
        this.requesterId = requesterId;
    }

    public String getPayerId() {
        return payerId;
    }

    public void setPayerId(String payerId) {
        this.payerId = payerId;
    }

    public String getRequesterWalletId() {
        return requesterWalletId;
    }

    public void setRequesterWalletId(String requesterWalletId) {
        this.requesterWalletId = requesterWalletId;
    }

    public String getPayerWalletId() {
        return payerWalletId;
    }

    public void setPayerWalletId(String payerWalletId) {
        this.payerWalletId = payerWalletId;
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

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public MoneyRequestResponse() {}
}
