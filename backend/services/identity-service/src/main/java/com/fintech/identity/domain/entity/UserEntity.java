package com.fintech.identity.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

/**
 * Entity đại diện cho tài khoản người dùng trong ewallet_identity_db (bảng users).
 */
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_users_phone", columnList = "phone_number"),
    @Index(name = "idx_users_status", columnList = "status"),
    @Index(name = "idx_users_branch", columnList = "branch_id"),
    @Index(name = "idx_users_username", columnList = "username")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserEntity {

    @Id
    @Column(length = 36, nullable = false)
    private String id;

    @Column(length = 50, unique = true)
    private String username;

    @Column(name = "phone_number", length = 15, nullable = false, unique = true)
    private String phoneNumber;

    @Column(name = "password_hash", length = 255, nullable = false)
    private String passwordHash;

    @Column(name = "full_name", length = 100)
    private String fullName;

    @Column(length = 100, unique = true)
    private String email;

    @Column(length = 20, nullable = false)
    @Builder.Default
    private String role = "ROLE_USER";

    @Column(length = 20, nullable = false)
    @Builder.Default
    private String status = "ACTIVE"; // ACTIVE, BLOCKED, CLOSED

    @Column(name = "kyc_tier", length = 20, nullable = false)
    @Builder.Default
    private String kycTier = "UNVERIFIED"; // UNVERIFIED, BASIC, VERIFIED, ENTERPRISE

    @Column(name = "branch_id", length = 50)
    @Builder.Default
    private String branchId = "BR_MAIN";

    @Column(name = "pin_hash", length = 255)
    private String pinHash;

    @Column(name = "pin_failed_attempts", nullable = false)
    @Builder.Default
    private Integer pinFailedAttempts = 0;

    @Column(name = "pin_locked_until")
    private Instant pinLockedUntil;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}
