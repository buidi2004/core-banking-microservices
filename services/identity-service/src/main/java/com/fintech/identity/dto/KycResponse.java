package com.fintech.identity.dto;

import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KycResponse {

    private String id;
    private String userId;
    private String documentType;
    private String documentNumber;
    private String frontImageUrl;
    private String backImageUrl;
    private String faceImageUrl;
    private String verificationStatus; // PENDING, APPROVED, REJECTED
    private String rejectReason;
    private String currentKycTier; // UNVERIFIED, BASIC, VERIFIED, ENTERPRISE
    private Instant createdAt;
    private Instant verifiedAt;
}
