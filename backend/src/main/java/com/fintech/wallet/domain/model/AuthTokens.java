package com.fintech.wallet.domain.model;

public class AuthTokens {
    private final String accessToken;
    private final String refreshToken;
    private final String deviceId;

    public AuthTokens(String accessToken, String refreshToken, String deviceId) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.deviceId = deviceId;
    }

    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
    public String getDeviceId() { return deviceId; }
}
