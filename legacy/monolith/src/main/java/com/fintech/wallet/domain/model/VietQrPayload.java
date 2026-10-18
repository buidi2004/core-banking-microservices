package com.fintech.wallet.domain.model;

import java.math.BigDecimal;

public class VietQrPayload {
    private final String bankBin;
    private final String accountNumber;
    private final BigDecimal amount;
    private final String purpose;
    private final String qrCodeString;

    public VietQrPayload(String bankBin, String accountNumber, BigDecimal amount, String purpose, String qrCodeString) {
        this.bankBin = bankBin;
        this.accountNumber = accountNumber;
        this.amount = amount;
        this.purpose = purpose;
        this.qrCodeString = qrCodeString;
    }

    public String getBankBin() { return bankBin; }
    public String getAccountNumber() { return accountNumber; }
    public BigDecimal getAmount() { return amount; }
    public String getPurpose() { return purpose; }
    public String getQrCodeString() { return qrCodeString; }
}
