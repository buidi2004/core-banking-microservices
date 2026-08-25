package com.fintech.wallet.domain.exception;

public class KycRequiredException extends RuntimeException {
    public KycRequiredException(String message) {
        super(message);
    }
}
