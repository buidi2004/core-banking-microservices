package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.Bank;

public class BankResponse {
    private String id;
    private String code;
    private String shortName;
    private String logoUrl;
    private boolean isInternal;

    public BankResponse(String id, String code, String shortName, String logoUrl, boolean isInternal) {
        this.id = id;
        this.code = code;
        this.shortName = shortName;
        this.logoUrl = logoUrl;
        this.isInternal = isInternal;
    }

    public static BankResponse fromDomain(Bank bank) {
        if (bank == null) return null;
        return new BankResponse(
                bank.getId(),
                bank.getBankCode(),
                bank.getBankName(),
                bank.getLogoUrl(),
                bank.isInternal()
        );
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getShortName() {
        return shortName;
    }

    public void setShortName(String shortName) {
        this.shortName = shortName;
    }

    public String getLogoUrl() {
        return logoUrl;
    }

    public void setLogoUrl(String logoUrl) {
        this.logoUrl = logoUrl;
    }

    public boolean isInternal() {
        return isInternal;
    }

    public void setInternal(boolean internal) {
        isInternal = internal;
    }
}
