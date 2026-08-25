package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.ReconciliationUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/reconciliation")
public class ReconciliationController {

    private final ReconciliationUseCase reconciliationUseCase;

    public ReconciliationController(ReconciliationUseCase reconciliationUseCase) {
        this.reconciliationUseCase = reconciliationUseCase;
    }

    @PostMapping("/run")
    public ResponseEntity<ApiResponse<Map<String, Object>>> runReconciliation() {
        Map<String, Object> result = reconciliationUseCase.runDailyReconciliation();
        return ResponseEntity.ok(ApiResponse.success("Daily reconciliation job completed", result));
    }
}
