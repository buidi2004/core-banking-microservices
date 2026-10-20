package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: Transactions (ewallet_payment_db)
 * Bản ghi giao dịch chuyển tiền / nạp / rút / thanh toán.
 * source_wallet_id / target_wallet_id là Logical ID (VARCHAR), không FK vật lý sang wallets.
 */
@Entity
@Table(name = "transactions", indexes = {
        @Index(name = "idx_transactions_source_wallet", columnList = "source_wallet_id"),
        @Index(name = "idx_transactions_target_wallet", columnList = "target_wallet_id"),
        @Index(name = "idx_transactions_sender", columnList = "sender_id, created_at DESC"),
        @Index(name = "idx_transactions_receiver", columnList = "receiver_id, created_at DESC"),
        @Index(name = "idx_transactions_status", columnList = "status")
})
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Transaction {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "transaction_code", length = 50, nullable = false, unique = true)
    private String transactionCode;

    @Column(name = "source_wallet_id", length = 36)
    private String sourceWalletId;

    @Column(name = "target_wallet_id", length = 36)
    private String targetWalletId;

    @Column(name = "sender_id", length = 36)
    private String senderId;

    @Column(name = "receiver_id", length = 36)
    private String receiverId;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false, columnDefinition = "bigint default 0")
    private Long fee;

    @Column(nullable = false, length = 10, columnDefinition = "varchar(10) default 'VND'")
    private String currency;

    @Column(nullable = false, length = 30)
    private String type;

    @Column(nullable = false, length = 30)
    private String status;

    @Column(name = "idempotency_key", length = 100, unique = true)
    private String idempotencyKey;

    @Column(name = "failure_reason", columnDefinition = "text")
    private String failureReason;

    @Column(columnDefinition = "text")
    private String note;

    /** Số dư ví nguồn ngay sau giao dịch (snapshot từ Wallet Service, dùng cho lịch sử biến động số dư). */
    @Column(name = "source_balance_after")
    private Long sourceBalanceAfter;

    /** Số dư ví đích ngay sau giao dịch (snapshot từ Wallet Service). */
    @Column(name = "target_balance_after")
    private Long targetBalanceAfter;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    @Version
    @Column(name = "version")
    private Long version;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (updatedAt == null) updatedAt = Instant.now();
        if (fee == null) fee = 0L;
        if (currency == null) currency = "VND";
        if (version == null) version = 0L;
    }

    public static Transaction initiate(String transactionCode, String sourceWalletId, String targetWalletId,
                                       String senderId, String receiverId, Long amount, String type, String note) {
        return Transaction.builder()
                .transactionCode(transactionCode)
                .sourceWalletId(sourceWalletId)
                .targetWalletId(targetWalletId)
                .senderId(senderId)
                .receiverId(receiverId)
                .amount(amount)
                .fee(0L)
                .currency("VND")
                .type(type)
                .status("INITIATED")
                .note(note)
                .build();
    }

    public void markDebited() { this.status = "DEBITED"; }
    public void markCreditPending() { this.status = "PENDING_CREDIT"; }
    public void markSuccess() { this.status = "SUCCESS"; }
    public void markFailed(String reason) { this.status = "FAILED"; this.failureReason = reason; }
    public void markReversed() { this.status = "REVERSED"; }
}
