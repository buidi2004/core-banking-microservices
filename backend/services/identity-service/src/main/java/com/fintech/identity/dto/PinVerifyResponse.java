package com.fintech.identity.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PinVerifyResponse {
    private String pinToken;
    private Long expiresInSeconds;
}

