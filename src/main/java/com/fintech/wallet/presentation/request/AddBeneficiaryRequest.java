package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;

public class AddBeneficiaryRequest {

    private String beneficiaryWalletId;
    private String nickname;
    private String bankCode;
    private String accountNumber;

    public String getBeneficiaryWalletId() { return beneficiaryWalletId; }
    public void setBeneficiaryWalletId(String beneficiaryWalletId) { this.beneficiaryWalletId = beneficiaryWalletId; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }
    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }
}
