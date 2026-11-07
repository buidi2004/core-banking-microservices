package com.fintech.identity.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KycAutoApproveRequest {

    @NotBlank(message = "userId is required")
    private String userId;

    private String sessionId;
    private Double livenessScore;
    private Double similarity;
    private String documentNumber;
    private String verifiedBy;
}

