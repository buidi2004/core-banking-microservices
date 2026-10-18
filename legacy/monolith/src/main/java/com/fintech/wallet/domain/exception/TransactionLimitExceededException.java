package com.fintech.wallet.domain.exception;

public class TransactionLimitExceededException extends IllegalArgumentException {
    public TransactionLimitExceededException(String message) {
        super(message);
    }
}
