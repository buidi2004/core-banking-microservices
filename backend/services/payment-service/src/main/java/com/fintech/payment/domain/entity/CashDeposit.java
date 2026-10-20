package com.fintech.payment.domain.entity;

import com.fintech.payment.exception.MakerCheckerViolationException;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA Entity: CashDeposit (ewallet_payment_db)
 * Quản lý giao dịch nạp tiền tại quầy theo quy chuẩn Maker-Checker (Four-Eyes Principle).
 */
@Entity
@Table(name = "cash_deposits", indexes = {
        @Index(name = "idx_cash_deposits_maker", columnList = "maker_id"),
        @Index(name = "idx_cash_deposits_status", columnList = "status"),
        @Index(name = "idx_cash_deposits_branch", columnList = "branch_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDeposit {

    public static final String STATUS_PENDING_APPROVAL = "PENDING_APPROVAL";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_COMPLETED = "COMPLETED";

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "deposit_code", length = 50, nullable = false, unique = true)
    private String depositCode;

    @Column(name = "account_number", length = 50, nullable = false)
    private String accountNumber;

    @Column(name = "customer_name", length = 100, nullable = false)
    private String customerName;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false, length = 10, columnDefinition = "varchar(10) default 'VND'")
    @Builder.Default
    private String currency = "VND";

    @Column(name = "maker_id", length = 36, nullable = false)
    private String makerId;

    @Column(name = "checker_id", length = 36)
    private String checkerId;

    @Column(name = "branch_id", length = 50, nullable = false, columnDefinition = "varchar(50) default 'BR_Q1'")
    @Builder.Default
    private String branchId = "BR_Q1";

    @Column(nullable = false, length = 30)
    @Builder.Default
    private String status = STATUS_PENDING_APPROVAL;

    @Column(name = "idempotency_key", length = 100, nullable = false, unique = true)
    private String idempotencyKey;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @Column(name = "approved_at")
    private Instant approvedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @PrePersist
    public void prePersist() {
        if (id == null) {
            id = UUID.randomUUID().toString();
        }
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    /**
     * Phê duyệt lệnh nạp tiền bởi Kiểm soát viên (Checker).
     * BẮT BUỘC: Checker ID khác Maker ID.
     */
    public void approve(String checkerId) {
        if (checkerId == null || checkerId.isBlank()) {
            throw new IllegalArgumentException("Checker ID không được để trống khi phê duyệt");
        }
        if (this.makerId != null && this.makerId.trim().equalsIgnoreCase(checkerId.trim())) {
            throw new MakerCheckerViolationException(this.makerId, checkerId);
        }
        if (!STATUS_PENDING_APPROVAL.equals(this.status)) {
            throw new IllegalStateException("Chỉ có thể phê duyệt giao dịch ở trạng thái PENDING_APPROVAL. Hiện tại: " + this.status);
        }

        this.checkerId = checkerId.trim();
        this.status = STATUS_APPROVED;
        this.approvedAt = Instant.now();
    }

    /**
     * Từ chối lệnh nạp tiền bởi Kiểm soát viên (Checker).
     * BẮT BUỘC: Checker ID khác Maker ID.
     */
    public void reject(String checkerId, String reason) {
        if (checkerId == null || checkerId.isBlank()) {
            throw new IllegalArgumentException("Checker ID không được để trống khi từ chối");
        }
        if (this.makerId != null && this.makerId.trim().equalsIgnoreCase(checkerId.trim())) {
            throw new MakerCheckerViolationException(this.makerId, checkerId);
        }
        if (!STATUS_PENDING_APPROVAL.equals(this.status)) {
            throw new IllegalStateException("Chỉ có thể từ chối giao dịch ở trạng thái PENDING_APPROVAL. Hiện tại: " + this.status);
        }

        this.checkerId = checkerId.trim();
        this.status = STATUS_REJECTED;
        this.rejectionReason = reason;
    }

    /**
     * Hoàn tất hạch toán và ghi nhận tiền vào ví khách hàng.
     */
    public void complete() {
        if (!STATUS_APPROVED.equals(this.status)) {
            throw new IllegalStateException("Chỉ có thể hoàn tất giao dịch đã được APPROVED. Hiện tại: " + this.status);
        }
        this.status = STATUS_COMPLETED;
        this.completedAt = Instant.now();
    }
}
