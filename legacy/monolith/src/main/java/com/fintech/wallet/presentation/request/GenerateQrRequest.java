package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;

public class GenerateQrRequest {

    @NotBlank(message = "Bank BIN is required")
    private String bankBin;

    @NotBlank(message = "Account number is required")
    private String accountNumber;

    @DecimalMin(value = "0.0", message = "Amount must be zero or positive")
    private BigDecimal amount;

    private String purpose;

    public String getBankBin() { return bankBin; }
    public void setBankBin(String bankBin) { this.bankBin = bankBin; }
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }
}
