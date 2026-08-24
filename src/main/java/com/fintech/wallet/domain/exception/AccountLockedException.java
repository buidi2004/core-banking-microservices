package com.fintech.wallet.domain.exception;

public class AccountLockedException extends IllegalArgumentException {
    public AccountLockedException(String message) {
        super(message);
    }
}
