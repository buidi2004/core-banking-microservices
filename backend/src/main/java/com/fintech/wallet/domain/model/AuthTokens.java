package com.fintech.wallet.domain.model;

public class AuthTokens {
    private final String accessToken;
    private final String refreshToken;
    private final String deviceId;
    private final String userId;

    public AuthTokens(String accessToken, String refreshToken, String deviceId, String userId) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.deviceId = deviceId;
        this.userId = userId;
    }

    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
    public String getDeviceId() { return deviceId; }
    public String getUserId() { return userId; }
}
