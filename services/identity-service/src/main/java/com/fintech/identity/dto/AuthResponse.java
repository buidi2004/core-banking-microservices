package com.fintech.identity.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {

    private String token; // Access token
    private String refreshToken;
    private String tokenType; // "Bearer"
    private Long expiresIn; // seconds
    private String userId;
    private String phoneNumber;
    private String fullName;
    private String email;
    private String role;
    private String kycTier;
}
