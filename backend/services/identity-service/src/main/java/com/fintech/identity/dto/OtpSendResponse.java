package com.fintech.identity.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpSendResponse {
    private String phoneNumber;
    private int expiresInSeconds;
    private String referenceId;
    private String message;
    /** Gmail chính chủ đã nhận OTP, đã che mờ (VD: bu***70@gmail.com) để hiển thị an toàn. */
    private String maskedEmail;
}

