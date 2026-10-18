package com.fintech.identity.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Entity đại diện cho hồ sơ chi tiết người dùng (bảng user_profiles).
 */
@Entity
@Table(name = "user_profiles", indexes = {
    @Index(name = "idx_profiles_user_id", columnList = "user_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileEntity {

    @Id
    @Column(length = 36, nullable = false)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false, unique = true)
    private String userId;

    @Column(name = "avatar_url", length = 255)
    private String avatarUrl;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(length = 10)
    private String gender; // MALE, FEMALE, OTHER

    @Column(name = "identity_card_number", length = 20, unique = true)
    private String identityCardNumber;

    @Column(name = "identity_card_issued_date")
    private LocalDate identityCardIssuedDate;

    @Column(name = "identity_card_issued_place", length = 100)
    private String identityCardIssuedPlace;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}
