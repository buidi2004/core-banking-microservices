package com.fintech.payment.dto;

import com.fintech.payment.domain.entity.BillSubscription;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillSubscriptionResponse {
    private String id;
    private String userId;
    private String walletId;
    private String billType;
    private String customerCode;
    private String providerCode;
    private Integer autoDebitDay;
    private String status;
    private String lastDeductedAt;
    private String createdAt;

    public static BillSubscriptionResponse from(BillSubscription sub) {
        return BillSubscriptionResponse.builder()
                .id(sub.getId() != null ? sub.getId().toString() : null)
                .userId(sub.getUserId())
                .walletId(sub.getWalletId())
                .billType(sub.getBillType())
                .customerCode(sub.getCustomerCode())
                .providerCode(sub.getProviderCode())
                .autoDebitDay(sub.getAutoDebitDay())
                .status(sub.getStatus())
                .lastDeductedAt(sub.getLastDeductedAt() != null ? sub.getLastDeductedAt().toString() : null)
                .createdAt(sub.getCreatedAt() != null ? sub.getCreatedAt().toString() : null)
                .build();
    }
}

