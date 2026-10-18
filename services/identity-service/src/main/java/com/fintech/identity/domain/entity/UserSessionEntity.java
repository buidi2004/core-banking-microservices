package com.fintech.identity.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

/**
 * Entity đại diện cho phiên làm việc thiết bị (bảng user_sessions).
 */
@Entity
@Table(name = "user_sessions", indexes = {
    @Index(name = "idx_sessions_user_id", columnList = "user_id"),
    @Index(name = "idx_sessions_token_hash", columnList = "refresh_token_hash")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSessionEntity {

    @Id
    @Column(length = 36, nullable = false)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "device_id", length = 100, nullable = false)
    private String deviceId;

    @Column(name = "device_name", length = 100)
    private String deviceName;

    @Column(name = "device_os", length = 50)
    private String deviceOs;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "refresh_token_hash", length = 255, nullable = false)
    private String refreshTokenHash;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "is_revoked", nullable = false)
    @Builder.Default
    private Boolean isRevoked = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "last_accessed_at")
    private Instant lastAccessedAt;
}
