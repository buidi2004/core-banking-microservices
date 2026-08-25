package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.PartnerWebhookUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/webhooks")
public class PartnerWebhookController {

    private final PartnerWebhookUseCase partnerWebhookUseCase;

    public PartnerWebhookController(PartnerWebhookUseCase partnerWebhookUseCase) {
        this.partnerWebhookUseCase = partnerWebhookUseCase;
    }

    @PostMapping("/napas/callback")
    public ResponseEntity<ApiResponse<Void>> napasCallback(@RequestBody Map<String, Object> payload) {
        partnerWebhookUseCase.processNapasCallback(payload);
        return ResponseEntity.ok(ApiResponse.success("Napas callback processed", null));
    }

    @PostMapping("/bank/deposit-notify")
    public ResponseEntity<ApiResponse<Void>> bankDepositNotify(
            @RequestParam String walletId,
            @RequestParam BigDecimal amount,
            @RequestParam String bankTxRef) {
        partnerWebhookUseCase.processBankDepositNotify(walletId, amount, bankTxRef);
        return ResponseEntity.ok(ApiResponse.success("Bank deposit notification processed", null));
    }

    @PostMapping("/merchants/callback")
    public ResponseEntity<ApiResponse<Void>> merchantCallback(@RequestBody Map<String, Object> payload) {
        return ResponseEntity.ok(ApiResponse.success("Merchant callback notification received", null));
    }
}
