package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;

public class RegisterDeviceTokenRequest {

    @NotBlank(message = "fcmToken is required")
    private String fcmToken;

    private String deviceType; // "ANDROID" or "IOS"

    public RegisterDeviceTokenRequest() {}

    public RegisterDeviceTokenRequest(String fcmToken, String deviceType) {
        this.fcmToken = fcmToken;
        this.deviceType = deviceType;
    }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }
}
