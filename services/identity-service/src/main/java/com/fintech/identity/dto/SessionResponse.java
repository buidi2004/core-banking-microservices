package com.fintech.identity.dto;

import lombok.*;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionResponse {

    private String id;
    private String deviceId;
    private String deviceName;
    private String deviceOs;
    private String ipAddress;
    private Instant createdAt;
    private Instant lastAccessedAt;
    private Instant expiresAt;
    private Boolean isCurrentDevice;
}
