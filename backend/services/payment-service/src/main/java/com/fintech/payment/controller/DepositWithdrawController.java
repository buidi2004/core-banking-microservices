package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import com.fintech.payment.security.PinTokenValidator;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class DepositWithdrawController {

    private final PaymentSagaOrchestrator sagaOrchestrator;
    private final PinTokenValidator pinTokenValidator;

    /**
     * Nạp tiền vào ví cá nhân (User Deposit).
     * POST /api/v1/payments/deposit
     */
    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<DepositResponse>> deposit(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @Valid @RequestBody DepositRequest request) {

        String userId = headerUserId != null ? headerUserId : "user-anonymous";
        log.info("Yêu cầu nạp tiền: userId={}, walletId={}, amount={}", userId, request.getWalletId(), request.getAmount());

        SagaContext ctx = sagaOrchestrator.deposit(
                userId,
                request.getWalletId(),
                request.getAmount(),
                request.getCurrency(),
                request.resolveIdempotencyKey()
        );

        Long balanceAfter = ctx.getTargetBalanceAfter() != null ? Long.parseLong(ctx.getTargetBalanceAfter()) : null;

        DepositResponse response = DepositResponse.builder()
                .transactionId(ctx.getTransactionId())
                .transactionCode(ctx.getTransactionCode())
                .walletId(ctx.getTargetWalletId())
                .amount(ctx.getAmount())
                .balanceAfter(balanceAfter)
                .currency(ctx.getCurrency())
                .status(ctx.getStatus())
                .message("Nạp tiền vào ví thành công")
                .build();

        return ResponseEntity.ok(ApiResponse.success("Nạp tiền vào ví thành công", response));
    }

    /**
     * Rút tiền từ ví về tài khoản ngân hàng (User Withdraw).
     * POST /api/v1/payments/withdraw
     */
    @PostMapping("/withdraw")
    public ResponseEntity<ApiResponse<WithdrawResponse>> withdraw(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestHeader(value = "X-Pin-Token", required = false) String headerPinToken,
            @Valid @RequestBody WithdrawRequest request) {

        String userId = headerUserId != null ? headerUserId : "user-anonymous";
        String pinToken = (request.getPinToken() != null && !request.getPinToken().isBlank())
                ? request.getPinToken()
                : headerPinToken;

        // 1. Xác thực pinToken
        if (!pinTokenValidator.validatePinToken(pinToken, userId)) {
            log.warn("Từ chối rút tiền: pinToken không hợp lệ hoặc đã hết hạn cho userId={}", userId);
            ApiResponse<WithdrawResponse> err = ApiResponse.error("INVALID_PIN_TOKEN", "Mã xác thực giao dịch (PIN) không hợp lệ hoặc đã hết hạn");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(err);
        }

        log.info("Yêu cầu rút tiền: userId={}, walletId={}, bankAccount={}, amount={}",
                userId, request.getWalletId(), request.getBankAccountId(), request.getAmount());

        try {
            SagaContext ctx = sagaOrchestrator.withdraw(
                    userId,
                    request.getWalletId(),
                    request.getAmount(),
                    request.getCurrency(),
                    request.getBankAccountId(),
                    request.resolveIdempotencyKey()
            );

            Long balanceAfter = ctx.getSourceBalanceAfter() != null ? Long.parseLong(ctx.getSourceBalanceAfter()) : null;

            WithdrawResponse response = WithdrawResponse.builder()
                    .transactionId(ctx.getTransactionId())
                    .transactionCode(ctx.getTransactionCode())
                    .walletId(ctx.getSourceWalletId())
                    .bankAccountId(request.getBankAccountId())
                    .amount(ctx.getAmount())
                    .balanceAfter(balanceAfter)
                    .currency(ctx.getCurrency())
                    .status(ctx.getStatus())
                    .message("Rút tiền về tài khoản ngân hàng thành công")
                    .build();

            return ResponseEntity.ok(ApiResponse.success("Rút tiền về tài khoản ngân hàng thành công", response));
        } catch (IllegalArgumentException e) {
            ApiResponse<WithdrawResponse> err = ApiResponse.error("INSUFFICIENT_FUNDS", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(err);
        }
    }
}
