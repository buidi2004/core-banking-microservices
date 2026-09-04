package com.fintech.wallet.presentation.request;

public class UnregisterDeviceTokenRequest {

    private String fcmToken;

    public UnregisterDeviceTokenRequest() {}

    public UnregisterDeviceTokenRequest(String fcmToken) {
        this.fcmToken = fcmToken;
    }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
}
