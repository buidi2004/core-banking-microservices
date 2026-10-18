package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "banks")
public class BankJpaEntity {

    @Id
    private String id;

    @Column(name = "bank_code", nullable = false, unique = true)
    private String bankCode;

    @Column(name = "bank_name", nullable = false)
    private String bankName;

    @Column(name = "logo_url")
    private String logoUrl;

    @Column(name = "is_internal", nullable = false)
    private boolean isInternal;

    public BankJpaEntity() {}

    public BankJpaEntity(String id, String bankCode, String bankName, String logoUrl, boolean isInternal) {
        this.id = id;
        this.bankCode = bankCode;
        this.bankName = bankName;
        this.logoUrl = logoUrl;
        this.isInternal = isInternal;
    }

    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }

    public String getBankCode() {
        return bankCode;
    }
    public void setBankCode(String bankCode) {
        this.bankCode = bankCode;
    }

    public String getBankName() {
        return bankName;
    }
    public void setBankName(String bankName) {
        this.bankName = bankName;
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
