package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: Banks (ewallet_payment_db)
 * Danh sách ngân hàng liên kết (VCB, MBB, TCB, VPB...).
 */
@Entity
@Table(name = "banks", uniqueConstraints = {
        @UniqueConstraint(name = "uk_banks_code", columnNames = "code"),
        @UniqueConstraint(name = "uk_banks_bin", columnNames = "bin")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Bank {

    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 20)
    private String code;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "short_name", length = 50, nullable = false)
    private String shortName;

    @Column(nullable = false, length = 10)
    private String bin;

    @Column(name = "logo_url", length = 255)
    private String logoUrl;

    @Column(name = "is_active", nullable = false, columnDefinition = "boolean default true")
    private Boolean active;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (active == null) active = true;
    }
}
