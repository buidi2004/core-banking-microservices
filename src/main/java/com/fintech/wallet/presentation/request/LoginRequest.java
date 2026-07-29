package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;

public class LoginRequest {

    @NotBlank(message = "Phone number is required")
    private String phoneNumber;

    @NotBlank(message = "Password is required")
    private String password;

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
