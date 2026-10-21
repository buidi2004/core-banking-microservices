package com.fintech.identity.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpSendRequest {
    @NotBlank(message = "Số điện thoại không được để trống")
    private String phoneNumber;

    private String email;

    @Builder.Default
    private String purpose = "FORGOT_PASSWORD";
}

