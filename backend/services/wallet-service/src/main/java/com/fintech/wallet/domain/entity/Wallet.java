package com.fintech.wallet.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: wallets (ewallet_wallet_db)
 * Chỉ chứa bảng wallets, tối ưu I/O và khóa bi quan SELECT FOR UPDATE.
 * user_id là Logical ID (VARCHAR), không FK vật lý sang users.
 */
@Entity
@Table(name = "wallets", uniqueConstraints = {
        @UniqueConstraint(name = "uk_wallets_user_id", columnNames = "user_id")
}, indexes = {
        @Index(name = "idx_wallets_status", columnList = "status")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Wallet {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(nullable = false, columnDefinition = "bigint default 0 check (balance >= 0)")
    private Long balance;

    @Column(name = "reserved_balance", nullable = false, columnDefinition = "bigint default 0 check (reserved_balance >= 0)")
    private Long reservedBalance;

    @Column(nullable = false, length = 10, columnDefinition = "varchar(10) default 'VND'")
    private String currency;

    @Column(nullable = false, length = 20, columnDefinition = "varchar(20) default 'ACTIVE'")
    private String status;

    @Column(name = "daily_limit", nullable = false, columnDefinition = "bigint default 50000000")
    private Long dailyLimit;

    @Column(name = "daily_spent", nullable = false, columnDefinition = "bigint default 0")
    private Long dailySpent;

    @Version
    @Column(name = "version")
    private Long version;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (updatedAt == null) updatedAt = Instant.now();
        if (balance == null) balance = 0L;
        if (reservedBalance == null) reservedBalance = 0L;
        if (currency == null) currency = "VND";
        if (status == null) status = "ACTIVE";
        if (dailyLimit == null) dailyLimit = 50000000L;
        if (dailySpent == null) dailySpent = 0L;
        if (version == null) version = 0L;
    }

    public Long availableBalance() {
        return balance - reservedBalance;
    }

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status);
    }
}
