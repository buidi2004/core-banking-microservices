package com.fintech.payment.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchTransferRequest {
    private String sourceWalletId;
    private String batchName;
    private String pinToken;

    @NotEmpty(message = "Danh sách chuyển tiền theo lô không được để trống")
    @Valid
    private List<BatchTransferItemRequest> items;
}

