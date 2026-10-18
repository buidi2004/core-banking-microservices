package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Merchant;
import com.fintech.wallet.domain.model.MerchantOrder;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.MerchantUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/v1/merchants")
public class MerchantController {

    private final MerchantUseCase merchantUseCase;

    public MerchantController(MerchantUseCase merchantUseCase) {
        this.merchantUseCase = merchantUseCase;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Merchant>> registerMerchant(
            @RequestParam String merchantName,
            @RequestParam String bankAccount) {
        Merchant merchant = merchantUseCase.registerMerchant(merchantName, bankAccount);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Merchant registered successfully", merchant));
    }

    @PostMapping("/payment-requests")
    public ResponseEntity<ApiResponse<MerchantOrder>> createPaymentRequest(
            @RequestParam String merchantId,
            @RequestParam String orderRef,
            @RequestParam BigDecimal amount,
            @RequestParam(defaultValue = "VND") String currency,
            @RequestParam(required = false) String callbackUrl) {
        MerchantOrder order = merchantUseCase.createPaymentRequest(merchantId, orderRef, amount, currency, callbackUrl);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Merchant payment request created", order));
    }

    @PostMapping("/payments/confirm")
    public ResponseEntity<ApiResponse<TransferResponse>> confirmPayment(
            Authentication auth,
            @RequestParam String walletId,
            @RequestParam String orderId) {
        String userId = auth.getName();
        Transaction transaction = merchantUseCase.confirmMerchantPayment(userId, walletId, orderId);
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Merchant payment confirmed", response));
    }
}
