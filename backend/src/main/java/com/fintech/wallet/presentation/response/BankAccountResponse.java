package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.BankAccount;

public class BankAccountResponse {

    private String id;
    private String bankCode;
    private String accountNumber;
    private String accountHolderName;
    private boolean isDefault;

    public BankAccountResponse(String id, String bankCode, String accountNumber, String accountHolderName, boolean isDefault) {
        this.id = id;
        this.bankCode = bankCode;
        this.accountNumber = accountNumber;
        this.accountHolderName = accountHolderName;
        this.isDefault = isDefault;
    }

    public static BankAccountResponse fromDomain(BankAccount account) {
        if (account == null) return null;
        return new BankAccountResponse(
                account.getId(),
                account.getBankCode(),
                account.getAccountNumber(),
                account.getAccountHolderName(),
                account.isDefault()
        );
    }

    public String getId() { return id; }
    public String getBankCode() { return bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public String getAccountHolderName() { return accountHolderName; }
    public boolean isDefault() { return isDefault; }
}
