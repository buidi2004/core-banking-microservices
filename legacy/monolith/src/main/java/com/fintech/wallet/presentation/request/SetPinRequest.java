package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class SetPinRequest {

    @NotBlank(message = "PIN is required")
    @Pattern(regexp = "^\\d{6}$", message = "PIN must be exactly 6 digits")
    private String pin;

    public String getPin() { return pin; }
    public void setPin(String pin) { this.pin = pin; }
}
