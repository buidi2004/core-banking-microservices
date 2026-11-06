package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Báo cáo Phân loại Nợ 5 Nhóm theo Thông tư 11/2021/TT-NHNN của Ngân hàng Nhà nước
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CicDebtReportResponse {
    private long totalLoans;
    private BigDecimal totalPrincipalOutstanding;
    private BigDecimal totalRiskProvision;

    // Nhóm 1: Nợ đủ tiêu chuẩn (Quá hạn <= 10 ngày, tỷ lệ trích 0%)
    private long group1Count;
    private BigDecimal group1Amount;

    // Nhóm 2: Nợ cần chú ý (Quá hạn 10 - 90 ngày, tỷ lệ trích 5%)
    private long group2Count;
    private BigDecimal group2Amount;

    // Nhóm 3: Nợ dưới tiêu chuẩn (Quá hạn 91 - 180 ngày, tỷ lệ trích 20%)
    private long group3Count;
    private BigDecimal group3Amount;

    // Nhóm 4: Nợ nghi ngờ (Quá hạn 181 - 360 ngày, tỷ lệ trích 50%)
    private long group4Count;
    private BigDecimal group4Amount;

    // Nhóm 5: Nợ có khả năng mất vốn (Quá hạn > 360 ngày, tỷ lệ trích 100%)
    private long group5Count;
    private BigDecimal group5Amount;

    private List<LoanApplicationResponse> contracts;
}

