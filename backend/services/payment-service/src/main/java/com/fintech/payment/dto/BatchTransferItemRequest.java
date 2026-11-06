package com.fintech.payment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchTransferItemRequest {
    @NotBlank(message = "Số tài khoản / SĐT người nhận không được để trống")
    private String accountNumber;

    private String recipientName;

    @NotNull(message = "Số tiền không được để trống")
    @Min(value = 1000, message = "Số tiền chuyển tối thiểu là 1.000 VND")
    private Long amount;

    private String note;
}

