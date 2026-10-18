package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: Beneficiaries (ewallet_payment_db)
 * Người thụ hưởng đã lưu của người dùng.
 */
@Entity
@Table(name = "beneficiaries", indexes = {
        @Index(name = "idx_beneficiaries_user", columnList = "user_id")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Beneficiary {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "beneficiary_user_id", length = 36)
    private String beneficiaryUserId;

    @Column(name = "beneficiary_phone", length = 15)
    private String beneficiaryPhone;

    @Column(length = 100)
    private String nickname;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
    }
}
