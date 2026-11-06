package com.fintech.payment.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VietQrGenerateRequest {
    @NotBlank(message = "Mã định danh ngân hàng (BIN) không được để trống")
    @JsonAlias({"acqId", "bin", "bankCode", "bank_bin"})
    private String bankBin;

    @NotBlank(message = "Số tài khoản thụ hưởng không được để trống")
    @JsonAlias({"accountNo", "account_number", "account", "phone", "phoneNumber"})
    private String accountNumber;

    @JsonAlias({"transAmount", "amount"})
    private BigDecimal amount;

    @JsonAlias({"addInfo", "description", "note", "purpose"})
    private String purpose;
}

