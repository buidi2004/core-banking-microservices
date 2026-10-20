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
public class BankAccountDto {
    private String id;
    private String bankId;
    private String bankCode;
    private String bankName;
    private String shortName;
    private String bin;
    private String logoUrl;
    private String accountNumber;
    private String accountHolderName;
    private boolean isVerified;
    private boolean isDefault;
    private Instant createdAt;
}

