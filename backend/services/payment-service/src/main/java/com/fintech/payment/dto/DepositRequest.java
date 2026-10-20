package com.fintech.payment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DepositRequest {

    private String walletId;

    @NotNull(message = "Số tiền không được để trống")
    @Min(value = 10000, message = "Số tiền nạp tối thiểu là 10,000 VND")
    private Long amount;

    @Builder.Default
    private String currency = "VND";

    private String requestId;
    private String idempotencyKey;

    public String resolveIdempotencyKey() {
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            return idempotencyKey;
        }
        return requestId;
    }
}

