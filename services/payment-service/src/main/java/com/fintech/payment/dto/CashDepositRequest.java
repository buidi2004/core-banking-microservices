package com.fintech.payment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * DTO yêu cầu nạp tiền mặt tại quầy (Cash Deposit Request).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashDepositRequest {

    @NotBlank(message = "Số tài khoản nhận không được để trống")
    private String accountNumber;

    @NotBlank(message = "Tên khách hàng không được để trống")
    private String customerName;

    @NotNull(message = "Số tiền nạp không được để trống")
    @Min(value = 1, message = "Số tiền nạp phải lớn hơn 0")
    private Long amount;

    @Builder.Default
    private String currency = "VND";

    @Builder.Default
    private String branchId = "BR_Q1";

    private String makerId;

    private String idempotencyKey;

    private String note;
}
