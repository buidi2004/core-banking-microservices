package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: FundingSource (ewallet_payment_db)
 * Nguồn tiền thanh toán: Ví, Tài khoản NH liên kết, Thẻ.
 */
@Entity
@Table(name = "funding_sources", indexes = {
        @Index(name = "idx_funding_sources_user", columnList = "user_id")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class FundingSource {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "source_type", length = 30, nullable = false)
    private String sourceType;

    @Column(name = "source_ref_id", length = 36, nullable = false)
    private String sourceRefId;

    @Column(name = "is_active", nullable = false, columnDefinition = "boolean default true")
    private Boolean active;

    @Column(nullable = false, columnDefinition = "int default 1")
    private Integer priority;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (active == null) active = true;
        if (priority == null) priority = 1;
    }
}
