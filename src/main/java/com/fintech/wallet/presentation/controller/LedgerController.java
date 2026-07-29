package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.presentation.request.CreateLedgerAccountRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ledger")
public class LedgerController {

    private final LedgerUseCase ledgerUseCase;

    public LedgerController(LedgerUseCase ledgerUseCase) {
        this.ledgerUseCase = ledgerUseCase;
    }

    @PostMapping("/accounts")
    public ResponseEntity<ApiResponse<LedgerAccount>> createAccount(@Valid @RequestBody CreateLedgerAccountRequest request) {
        LedgerAccount account = ledgerUseCase.createAccount(
                request.getAccountName(),
                request.getAccountType(),
                request.getCurrency()
        );
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Ledger account created successfully", account));
    }

    @GetMapping("/accounts")
    public ResponseEntity<ApiResponse<List<LedgerAccount>>> getAllAccounts() {
        List<LedgerAccount> accounts = ledgerUseCase.getAllAccounts();
        return ResponseEntity.ok(ApiResponse.success("Ledger accounts retrieved", accounts));
    }

    @GetMapping("/entries")
    public ResponseEntity<ApiResponse<List<JournalEntry>>> getAllJournalEntries() {
        List<JournalEntry> entries = ledgerUseCase.getAllJournalEntries();
        return ResponseEntity.ok(ApiResponse.success("Journal entries retrieved", entries));
    }
}
