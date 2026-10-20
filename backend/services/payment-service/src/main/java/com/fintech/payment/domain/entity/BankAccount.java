package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: BankAccount (ewallet_payment_db)
 * Tài khoản ngân hàng người dùng liên kết.
 */
@Entity
@Table(name = "bank_accounts", indexes = {
        @Index(name = "idx_bank_accounts_user", columnList = "user_id")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class BankAccount {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "bank_id", length = 36, nullable = false)
    private String bankId;

    @Column(name = "account_number", length = 50, nullable = false)
    private String accountNumber;

    @Column(name = "account_holder_name", length = 100, nullable = false)
    private String accountHolderName;

    @Column(name = "is_verified", nullable = false, columnDefinition = "boolean default false")
    private Boolean verified;

    @Column(name = "is_default", nullable = false, columnDefinition = "boolean default false")
    private Boolean defaultAccount;

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
        if (verified == null) verified = false;
        if (defaultAccount == null) defaultAccount = false;
    }
}
