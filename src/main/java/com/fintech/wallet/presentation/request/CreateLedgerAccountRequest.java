package com.fintech.wallet.presentation.request;

import com.fintech.wallet.domain.model.AccountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class CreateLedgerAccountRequest {

    @NotBlank(message = "Account name is required")
    private String accountName;

    @NotNull(message = "Account type is required")
    private AccountType accountType;

    @NotBlank(message = "Currency is required")
    private String currency;

    public String getAccountName() { return accountName; }
    public void setAccountName(String accountName) { this.accountName = accountName; }
    public AccountType getAccountType() { return accountType; }
    public void setAccountType(AccountType accountType) { this.accountType = accountType; }
    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
}
