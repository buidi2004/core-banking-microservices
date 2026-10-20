package com.fintech.identity.exception;

public class PinLockedException extends RuntimeException {
    public PinLockedException(String message) {
        super(message);
    }
}

