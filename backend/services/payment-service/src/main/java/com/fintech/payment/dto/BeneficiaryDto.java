package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BeneficiaryDto {
    private String id;
    private String name;
    private String fullName;
    private String nickname;
    private String phoneNumber;
    private String bankCode;
    private String accountNumber;
    private String beneficiaryUserId;
    private String beneficiaryWalletId;
    private Instant createdAt;
}

