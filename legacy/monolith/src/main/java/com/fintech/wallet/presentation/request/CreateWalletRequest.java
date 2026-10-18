package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;

public class CreateWalletRequest {

    @NotBlank(message = "Owner ID is required")
    private String ownerId;

    @NotBlank(message = "Currency is required")
    private String currency;

    public String getOwnerId() {
        return ownerId;
    }
    public void setOwnerId(String ownerId) {
        this.ownerId = ownerId;
    }

    public String getCurrency() {
        return currency;
    }
    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public CreateWalletRequest() {}

    public CreateWalletRequest(String ownerId, String currency) {
        this.ownerId = ownerId;
        this.currency = currency;
    }
}
