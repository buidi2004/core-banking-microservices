package com.fintech.ledger.domain.exception;

public class LedgerUnbalancedException extends RuntimeException {

    public LedgerUnbalancedException(String message) {
        super(message);
    }
}
