package com.fintech.ledger.domain.model;

public enum AccountType {
    ASSET,
    LIABILITY,
    EQUITY,
    REVENUE,
    EXPENSE;

    public boolean isDebitNormal() {
        return this == ASSET || this == EXPENSE;
    }
}
