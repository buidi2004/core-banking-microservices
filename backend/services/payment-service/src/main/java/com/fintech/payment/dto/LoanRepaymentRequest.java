package com.fintech.payment.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoanRepaymentRequest {
    @NotNull
    private Integer termNumber;

    private BigDecimal amount;

    private String pinToken;
}

