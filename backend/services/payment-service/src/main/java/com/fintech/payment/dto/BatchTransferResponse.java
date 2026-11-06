package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchTransferResponse {
    private String batchId;
    private String batchName;
    private int totalCount;
    private int successCount;
    private int failedCount;
    private Long totalAmount;
    private Long successAmount;
    private List<BatchTransferItemResult> items;
}

