package com.fintech.wallet.presentation.response;

public class RecipientInfoResponse {
    private String walletId;
    private String phoneNumber;
    private String maskedName;
    private String fullName;

    public RecipientInfoResponse() {}

    public RecipientInfoResponse(String walletId, String phoneNumber, String maskedName) {
        this.walletId = walletId;
        this.phoneNumber = phoneNumber;
        this.maskedName = maskedName;
        this.fullName = maskedName; // Default for backward compatibility
    }

    public RecipientInfoResponse(String walletId, String phoneNumber, String maskedName, String fullName) {
        this.walletId = walletId;
        this.phoneNumber = phoneNumber;
        this.maskedName = maskedName;
        this.fullName = fullName;
    }

    public String getWalletId() {
        return walletId;
    }

    public void setWalletId(String walletId) {
        this.walletId = walletId;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getMaskedName() {
        return maskedName;
    }

    public void setMaskedName(String maskedName) {
        this.maskedName = maskedName;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
}
