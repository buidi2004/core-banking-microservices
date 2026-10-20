package com.fintech.identity.dto;

import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileResponse {

    private String userId;
    private String phoneNumber;
    private String fullName;
    private String email;
    private String role;
    private String status;
    private String kycTier;
    private String avatarUrl;
    private LocalDate dateOfBirth;
    private String address;
    private String gender;
    private String identityCardNumber;
    private LocalDate identityCardIssuedDate;
    private String identityCardIssuedPlace;
    private Instant createdAt;
    private Instant updatedAt;
}
