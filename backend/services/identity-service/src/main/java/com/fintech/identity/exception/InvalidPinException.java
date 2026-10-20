package com.fintech.identity.exception;

import lombok.Getter;

@Getter
public class InvalidPinException extends RuntimeException {
    private final int remainingAttempts;

    public InvalidPinException(String message, int remainingAttempts) {
        super(message);
        this.remainingAttempts = remainingAttempts;
    }
}

