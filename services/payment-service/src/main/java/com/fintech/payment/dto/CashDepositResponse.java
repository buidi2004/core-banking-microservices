package com.fintech.payment.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fintech.payment.domain.entity.CashDeposit;
import lombok.*;

import java.time.Instant;

/**
 * DTO phản hồi thông tin giao dịch nạp tiền tại quầy.
 * Tương thích song song cả backend API và frontend Cash Deposit Portal.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDepositResponse {

    private String id;

    @JsonProperty("depositCode")
    private String depositCode;

    private String customerName;
    private String accountNumber;
    private Long amount;
    private String currency;
    private String makerId;
    private String makerName;
    private String checkerId;
    private String checkerName;
    private String branchId;
    private String status;
    private String idempotencyKey;
    private String rejectionReason;
    private Instant createdAt;
    private Instant approvedAt;
    private Instant completedAt;
    private String note;
    private String hash;

    @JsonProperty("code")
    public String getCode() {
        return depositCode;
    }

    @JsonProperty("timestamp")
    public String getTimestamp() {
        return createdAt != null ? createdAt.toString() : null;
    }

    public static CashDepositResponse from(CashDeposit entity) {
        if (entity == null) return null;

        String mName = "Cán bộ (" + entity.getMakerId() + ")";
        if ("t0000001-0000-0000-0000-000000000001".equalsIgnoreCase(entity.getMakerId())) {
            mName = "Teller Nguyễn Văn A";
        }

        String cName = null;
        if (CashDeposit.STATUS_COMPLETED.equals(entity.getStatus()) && "AUTO_RULE".equalsIgnoreCase(entity.getCheckerId())) {
            cName = "Hệ thống tự duyệt (≤50M)";
        } else if (entity.getCheckerId() != null) {
            if ("m0000001-0000-0000-0000-000000000001".equalsIgnoreCase(entity.getCheckerId())) {
                cName = "Manager Lê Hoàng C";
            } else {
                cName = "Kiểm soát viên (" + entity.getCheckerId() + ")";
            }
        }

        String receiptHash = null;
        if (CashDeposit.STATUS_COMPLETED.equals(entity.getStatus()) || CashDeposit.STATUS_APPROVED.equals(entity.getStatus())) {
            String seed = entity.getDepositCode() + "-" + entity.getAmount() + "-" + entity.getAccountNumber();
            receiptHash = "f8a" + Integer.toHexString(Math.abs(seed.hashCode())) + "e49b2c710d8a9e";
        }

        return CashDepositResponse.builder()
                .id(entity.getId())
                .depositCode(entity.getDepositCode())
                .customerName(entity.getCustomerName())
                .accountNumber(entity.getAccountNumber())
                .amount(entity.getAmount())
                .currency(entity.getCurrency())
                .makerId(entity.getMakerId())
                .makerName(mName)
                .checkerId(entity.getCheckerId())
                .checkerName(cName)
                .branchId(entity.getBranchId())
                .status(entity.getStatus())
                .idempotencyKey(entity.getIdempotencyKey())
                .rejectionReason(entity.getRejectionReason())
                .createdAt(entity.getCreatedAt())
                .approvedAt(entity.getApprovedAt())
                .completedAt(entity.getCompletedAt())
                .hash(receiptHash)
                .build();
    }
}
