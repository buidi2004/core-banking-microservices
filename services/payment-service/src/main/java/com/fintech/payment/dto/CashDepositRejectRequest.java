package com.fintech.payment.dto;

import lombok.*;

/**
 * DTO từ chối lệnh nạp tiền tại quầy bởi Kiểm soát viên (Checker / Manager).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDepositRejectRequest {
    private String checkerId;
    private String role;
    private String reason;
}
