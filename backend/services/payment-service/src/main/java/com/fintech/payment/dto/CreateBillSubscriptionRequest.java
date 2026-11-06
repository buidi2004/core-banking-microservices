package com.fintech.payment.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateBillSubscriptionRequest {
    private String walletId;

    @NotBlank(message = "Loại hóa đơn không được để trống (ELECTRICITY, WATER, INTERNET, TUITION)")
    private String billType;

    @NotBlank(message = "Mã khách hàng / Danh bộ không được để trống")
    private String customerCode;

    @NotBlank(message = "Mã nhà cung cấp không được để trống")
    private String providerCode;

    @Min(value = 1, message = "Ngày trích nợ từ ngày 1 đến ngày 28 hàng tháng")
    @Max(value = 28, message = "Ngày trích nợ từ ngày 1 đến ngày 28 hàng tháng")
    @Builder.Default
    private Integer autoDebitDay = 5;
}

