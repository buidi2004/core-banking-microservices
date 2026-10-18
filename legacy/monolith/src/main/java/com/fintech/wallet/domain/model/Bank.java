package com.fintech.wallet.domain.model;

import java.util.Objects;
import java.util.UUID;

public class Bank {
    private final String id;
    private final String bankCode;
    private final String bankName;
    private final String logoUrl;
    private final boolean internal;

    public Bank(String id, String bankCode, String bankName, String logoUrl, boolean internal) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.bankCode = bankCode;
        this.bankName = bankName;
        this.logoUrl = logoUrl;
        this.internal = internal;
    }

    public String getId() {
        return id;
    }

    public String getBankCode() {
        return bankCode;
    }

    public String getBankName() {
        return bankName;
    }

    public String getLogoUrl() {
        return logoUrl;
    }

    public boolean isInternal() {
        return internal;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Bank bank = (Bank) o;
        return Objects.equals(id, bank.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
