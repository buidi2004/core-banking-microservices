package com.fintech.payment.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardStatusRequest {
    @NotBlank(message = "Trạng thái không được để trống (ACTIVE, LOCKED)")
    private String status;
}

