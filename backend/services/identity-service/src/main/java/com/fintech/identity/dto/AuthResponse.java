package com.fintech.identity.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AuthResponse {

    private String token; // Access token
    private String refreshToken;
    private String tokenType; // "Bearer"
    private Long expiresIn; // seconds
    private String userId;
    private String username;
    private String phoneNumber;
    private String fullName;
    private String email;
    private String role;
    private List<String> roles;
    private String branchId;
    private String kycTier;

    public String getAccessToken() {
        return token;
    }
}
