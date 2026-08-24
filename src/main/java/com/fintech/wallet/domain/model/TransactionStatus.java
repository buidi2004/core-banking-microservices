package com.fintech.wallet.domain.model;

public enum TransactionStatus {
    INITIATED,
    PENDING_CONFIRMATION,
    PROCESSING,
    PENDING,
    SUCCESS,
    FAILED,
    PENDING_REVERSAL,
    REVERSED
}
