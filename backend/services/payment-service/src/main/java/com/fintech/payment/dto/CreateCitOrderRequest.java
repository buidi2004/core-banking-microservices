package com.fintech.payment.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateCitOrderRequest {
    @NotBlank(message = "Chi nhánh xuất quỹ không được để trống")
    private String fromBranchId;

    @NotBlank(message = "Chi nhánh / Đích nhập quỹ không được để trống")
    private String toBranchId;

    @NotNull(message = "Số tiền điều chuyển không được để trống")
    @DecimalMin(value = "1000000", message = "Số tiền điều chuyển tối thiểu là 1.000.000 VND")
    private BigDecimal amount;

    private String currency;

    @NotBlank(message = "Tên cán bộ áp tải không được để trống")
    private String transportStaffName;

    @NotBlank(message = "Số niêm phong túi tiền (Seal) không được để trống")
    private String sealNumber;

    private String note;
}

