package com.fintech.payment.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransferRequest {
    @NotBlank(message = "sourceUserId là bắt buộc")
    private String sourceUserId;

    @NotBlank(message = "targetUserId là bắt buộc")
    private String targetUserId;

    @NotNull(message = "amount là bắt buộc")
    @Positive(message = "amount phải lớn hơn 0")
    private Long amount;

    private String currency;

    private String note;

    @NotBlank(message = "idempotencyKey là bắt buộc")
    private String idempotencyKey;

    private String pinToken;
}
