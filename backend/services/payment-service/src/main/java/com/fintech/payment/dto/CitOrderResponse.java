package com.fintech.payment.dto;

import com.fintech.payment.domain.entity.CashInTransitOrder;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CitOrderResponse {
    private String id;
    private String orderCode;
    private String fromBranchId;
    private String toBranchId;
    private BigDecimal amount;
    private String currency;
    private String transportStaffName;
    private String sealNumber;
    private String note;
    private String status;
    private String createdBy;
    private String approvedBy;
    private String createdAt;
    private String approvedAt;

    public static CitOrderResponse from(CashInTransitOrder order) {
        return CitOrderResponse.builder()
                .id(order.getId() != null ? order.getId().toString() : null)
                .orderCode(order.getOrderCode())
                .fromBranchId(order.getFromBranchId())
                .toBranchId(order.getToBranchId())
                .amount(order.getAmount())
                .currency(order.getCurrency())
                .transportStaffName(order.getTransportStaffName())
                .sealNumber(order.getSealNumber())
                .note(order.getNote())
                .status(order.getStatus())
                .createdBy(order.getCreatedBy())
                .approvedBy(order.getApprovedBy())
                .createdAt(order.getCreatedAt() != null ? order.getCreatedAt().toString() : null)
                .approvedAt(order.getApprovedAt() != null ? order.getApprovedAt().toString() : null)
                .build();
    }
}

