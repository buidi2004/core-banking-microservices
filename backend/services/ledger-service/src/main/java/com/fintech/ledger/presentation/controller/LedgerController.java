package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.presentation.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1/ledger")
public class LedgerController {

    private final LedgerService ledgerService;

    public LedgerController(LedgerService ledgerService) {
        this.ledgerService = ledgerService;
    }

    // ---------------------------------------------------------------------------
    // Tra cứu tài khoản & Tổng phát sinh Sổ cái (Frontend / Dashboard)
    // ---------------------------------------------------------------------------

    /**
     * API trả về tổng phát sinh Sổ cái kép cho Frontend:
     * - Tổng Nợ (Debit), Tổng Có (Credit), Delta = 0, Cân bằng (balanced)
     * - Chi tiết Nợ TK 1011 (Quỹ tiền mặt mặt đất) và Có TK 4211 (Tiền gửi ví khách hàng)
     */
    @GetMapping({"/summary", "/turnover-summary"})
    public ResponseEntity<ApiResponse<LedgerService.LedgerTurnoverSummary>> getTurnoverSummary() {
        return ResponseEntity.ok(ApiResponse.ok("Ledger turnover summary retrieved",
                ledgerService.getTurnoverSummary()));
    }

    @GetMapping("/accounts")
    public ResponseEntity<ApiResponse<List<LedgerAccount>>> getAccounts() {
        return ResponseEntity.ok(ApiResponse.ok("Ledger accounts retrieved", ledgerService.getAccounts()));
    }

    @GetMapping("/accounts/balance-check")
    public ResponseEntity<ApiResponse<LedgerService.LedgerReconciliationResult>> checkLedgerBalance() {
        // Đối soát toàn sổ: Σ Debit phải bằng Σ Credit
        return ResponseEntity.ok(ApiResponse.ok("Ledger balance verification",
                ledgerService.verifyLedgerBalance()));
    }

    /**
     * Sao kê theo ví: các dòng bút toán của tài khoản CUSTOMER_DEPOSITS:{walletId},
     * lọc theo khoảng thời gian (from/to định dạng ISO-8601, ví dụ 2025-07-01T00:00:00Z).
     */
    @GetMapping("/statement/{walletId}")
    public ResponseEntity<ApiResponse<List<LedgerPosting>>> getWalletStatement(
            @PathVariable("walletId") String walletId,
            @RequestParam(value = "from", required = false) String from,
            @RequestParam(value = "to", required = false) String to) {
        Instant fromDate = parseInstant(from, "from");
        Instant toDate = parseInstant(to, "to");
        List<LedgerPosting> statement = ledgerService.getWalletStatement(walletId, fromDate, toDate);
        return ResponseEntity.ok(ApiResponse.ok("Wallet statement retrieved", statement));
    }

    @GetMapping("/statement/{walletId}/account")
    public ResponseEntity<ApiResponse<LedgerAccount>> getWalletAccount(
            @PathVariable("walletId") String walletId) {
        return ResponseEntity.ok(ApiResponse.ok("Wallet ledger account",
                ledgerService.getWalletAccount(walletId)));
    }

    // ---------------------------------------------------------------------------
    // Tra cứu chứng từ ghi sổ
    // ---------------------------------------------------------------------------

    @GetMapping("/entries")
    public ResponseEntity<ApiResponse<List<JournalEntry>>> getJournalEntries() {
        return ResponseEntity.ok(ApiResponse.ok("Journal entries retrieved", ledgerService.getJournalEntries()));
    }

    @GetMapping("/entries/{entryId}")
    public ResponseEntity<ApiResponse<JournalEntry>> getJournalEntry(
            @PathVariable("entryId") String entryId) {
        return ResponseEntity.ok(ApiResponse.ok("Journal entry retrieved", ledgerService.getJournalEntry(entryId)));
    }

    /** Sao kê theo giao dịch: các chứng từ gốc + bù của 1 transactionId */
    @GetMapping("/transactions/{transactionId}")
    public ResponseEntity<ApiResponse<List<JournalEntry>>> getEntriesByTransaction(
            @PathVariable("transactionId") String transactionId) {
        return ResponseEntity.ok(ApiResponse.ok("Transaction journal entries retrieved",
                ledgerService.getJournalEntriesByTransaction(transactionId)));
    }

    private Instant parseInstant(String value, String param) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Invalid '" + param + "' date-time, expected ISO-8601 instant", e);
        }
    }
}
