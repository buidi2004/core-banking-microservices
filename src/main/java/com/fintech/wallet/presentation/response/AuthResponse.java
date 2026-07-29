package com.fintech.wallet.presentation.response;

public class AuthResponse {

    private String userId;
    private String accessToken;

    public AuthResponse(String userId, String accessToken) {
        this.userId = userId;
        this.accessToken = accessToken;
    }

    public String getUserId() { return userId; }
    public String getAccessToken() { return accessToken; }
}
