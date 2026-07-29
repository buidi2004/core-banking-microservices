package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class WithdrawRequest {

    private String requestId;

    @NotBlank(message = "Wallet ID is required")
    private String walletId;

    @NotBlank(message = "Bank account ID is required")
    private String bankAccountId;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
    private BigDecimal amount;

    @NotBlank(message = "Currency is required")
    private String currency;

    @NotBlank(message = "PIN verification token is required")
    private String pinToken;

    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }
    public String getWalletId() { return walletId; }
    public void setWalletId(String walletId) { this.walletId = walletId; }
    public String getBankAccountId() { return bankAccountId; }
    public void setBankAccountId(String bankAccountId) { this.bankAccountId = bankAccountId; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
    public String getPinToken() { return pinToken; }
    public void setPinToken(String pinToken) { this.pinToken = pinToken; }
}
