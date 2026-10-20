package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.presentation.dto.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Controller chuyên trách các truy vấn / báo cáo Sổ cái phục vụ Frontend:
 * - GET /api/v1/ledger/cash-summary: Trả về tổng Nợ 1011 (Quỹ tiền mặt) và tổng Có 4211 (Ví khách hàng),
 *   định lý bảo toàn Delta = 0 và trạng thái cân bằng tuyệt đối.
 */
@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1/ledger")
public class LedgerQueryController {

    private final LedgerService ledgerService;

    public LedgerQueryController(LedgerService ledgerService) {
        this.ledgerService = ledgerService;
    }

    /**
     * GET /api/v1/ledger/cash-summary
     * Trả về tổng phát sinh Nợ TK 1011 (Quỹ tiền mặt) và Có TK 4211 (Tiền gửi ví khách hàng),
     * Delta = 0.00 VND (cân bằng 100%) cho Frontend Dashboard.
     */
    @GetMapping({"/cash-summary", "/cash-deposit/summary"})
    public ResponseEntity<ApiResponse<CashSummaryResponse>> getCashSummary() {
        LedgerService.LedgerTurnoverSummary summary = ledgerService.getTurnoverSummary();
        CashSummaryResponse response = new CashSummaryResponse(
                summary.debit1011(),
                summary.credit4211(),
                summary.debit1011(),
                summary.credit4211(),
                summary.cashDelta(),
                summary.balanced(),
                summary.currency(),
                summary.totalEntries(),
                summary.totalPostings(),
                summary.generatedAt()
        );
        return ResponseEntity.ok(ApiResponse.ok("Cash summary retrieved", response));
    }

    public record CashSummaryResponse(
            BigDecimal totalDebit1011,
            BigDecimal totalCredit4211,
            BigDecimal debit1011,
            BigDecimal credit4211,
            BigDecimal delta,
            boolean balanced,
            String currency,
            long totalEntries,
            long totalPostings,
            Instant timestamp
    ) {
    }
}
