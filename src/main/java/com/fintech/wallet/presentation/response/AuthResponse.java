package com.fintech.wallet.presentation.response;

public class AuthResponse {

    private String userId;
    private String accessToken;
    private String refreshToken;

    public AuthResponse(String userId, String accessToken, String refreshToken) {
        this.userId = userId;
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
    }

    public String getUserId() { return userId; }
    public String getAccessToken() { return accessToken; }
    public String getRefreshToken() { return refreshToken; }
}
