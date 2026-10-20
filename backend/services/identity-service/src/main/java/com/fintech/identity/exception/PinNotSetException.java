package com.fintech.identity.exception;

public class PinNotSetException extends RuntimeException {
    public PinNotSetException(String message) {
        super(message);
    }
}

