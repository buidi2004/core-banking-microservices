package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateBeneficiaryRequest {
    private String name;
    private String fullName;
    private String nickname;
    private String phoneNumber;
    private String bankCode;
    private String accountNumber;
    private String beneficiaryUserId;
    private String beneficiaryWalletId;
}

