package com.fintech.wallet.domain.exception;

public class LedgerUnbalancedException extends RuntimeException {
    public LedgerUnbalancedException(String message) {
        super(message);
    }
}
