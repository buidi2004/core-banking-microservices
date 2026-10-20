package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller cung cấp alias endpoint dưới tiền tố /api/v1/wallets
 * để tương thích hoàn toàn với các hợp đồng mobile (POST /wallets/deposit, POST /wallets/withdraw).
 */
@RestController
@RequestMapping("/api/v1/wallets")
@RequiredArgsConstructor
public class WalletMutationController {

    private final DepositWithdrawController depositWithdrawController;

    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<DepositResponse>> deposit(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @Valid @RequestBody DepositRequest request) {
        return depositWithdrawController.deposit(headerUserId, request);
    }

    @PostMapping("/withdraw")
    public ResponseEntity<ApiResponse<WithdrawResponse>> withdraw(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestHeader(value = "X-Pin-Token", required = false) String headerPinToken,
            @Valid @RequestBody WithdrawRequest request) {
        return depositWithdrawController.withdraw(headerUserId, headerPinToken, request);
    }
}

