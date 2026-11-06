package com.fintech.payment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateScheduledTransferRequest {

    @NotBlank(message = "Người nhận không được để trống")
    private String targetUserId;

    private String targetPhoneNumber;
    private String targetCustomerName;

    @NotNull(message = "Số tiền không được để trống")
    @Min(value = 1000, message = "Số tiền chuyển tối thiểu là 1.000 VND")
    private Long amount;

    private String currency;
    private String note;

    @Builder.Default
    private String frequency = "ONCE"; // ONCE, DAILY, WEEKLY, MONTHLY

    private Integer dayOfMonth; // 1..31 if MONTHLY

    private Instant executeAt; // Thời điểm thực hiện (nếu rỗng mặc định ngay lập tức hoặc ngày mai)
}

