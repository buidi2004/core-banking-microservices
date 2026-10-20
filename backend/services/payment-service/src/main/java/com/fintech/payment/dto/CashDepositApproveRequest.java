package com.fintech.payment.dto;

import lombok.*;

/**
 * DTO phê duyệt lệnh nạp tiền tại quầy bởi Kiểm soát viên (Checker / Manager).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDepositApproveRequest {
    private String checkerId;
    private String role;
    private String note;
}
