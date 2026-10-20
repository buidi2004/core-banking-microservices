package com.fintech.payment.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MoneyRequestRequest {
    @NotBlank(message = "requesterId là bắt buộc")
    private String requesterId;

    @NotBlank(message = "targetUserId là bắt buộc")
    private String targetUserId;

    @NotNull(message = "amount là bắt buộc")
    @Positive(message = "amount phải lớn hơn 0")
    private Long amount;

    private String note;

    private Integer expiresInHours;
}
