package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cash_in_transit_orders", indexes = {
        @Index(name = "idx_cit_status", columnList = "status"),
        @Index(name = "idx_cit_branches", columnList = "from_branch_id, to_branch_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashInTransitOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "order_code", length = 50, nullable = false, unique = true)
    private String orderCode;

    @Column(name = "from_branch_id", length = 50, nullable = false)
    private String fromBranchId;

    @Column(name = "to_branch_id", length = 50, nullable = false)
    private String toBranchId;

    @Column(name = "amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal amount;

    @Column(name = "currency", length = 10, nullable = false)
    @Builder.Default
    private String currency = "VND";

    @Column(name = "transport_staff_name", length = 100, nullable = false)
    private String transportStaffName;

    @Column(name = "seal_number", length = 100, nullable = false)
    private String sealNumber;

    @Column(name = "note", length = 255)
    private String note;

    @Column(name = "status", length = 30, nullable = false)
    @Builder.Default
    private String status = "PENDING_APPROVAL";

    @Column(name = "created_by", length = 50, nullable = false)
    private String createdBy;

    @Column(name = "approved_by", length = 50)
    private String approvedBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "approved_at")
    private Instant approvedAt;
}

