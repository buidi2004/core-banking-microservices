package com.fintech.notification.dto;

import jakarta.validation.constraints.NotBlank;

public class RegisterDeviceTokenRequest {

    @NotBlank(message = "fcmToken is required")
    private String fcmToken;

    private String deviceType;

    private String deviceModel;

    private String appVersion;

    public RegisterDeviceTokenRequest() {
    }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public String getDeviceModel() { return deviceModel; }
    public void setDeviceModel(String deviceModel) { this.deviceModel = deviceModel; }

    public String getAppVersion() { return appVersion; }
    public void setAppVersion(String appVersion) { this.appVersion = appVersion; }
}
