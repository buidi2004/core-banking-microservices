package com.fintech.wallet.domain.exception;

public class InvalidPinException extends RuntimeException {
    public InvalidPinException(String message) {
        super(message);
    }
}
