package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Controller cung cấp alias endpoint dưới tiền tố /api/v1/wallets
 * để tương thích hoàn toàn với các hợp đồng mobile (POST /wallets/deposit, POST /wallets/withdraw, POST /wallets/transfer/init, POST /wallets/transfer/{id}/confirm).
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/wallets")
@RequiredArgsConstructor
public class WalletMutationController {

    private final DepositWithdrawController depositWithdrawController;
    private final Map<String, Map<String, Object>> pendingTransfers = new ConcurrentHashMap<>();

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

    @PostMapping("/transfer/init")
    public ResponseEntity<ApiResponse<Map<String, Object>>> transferInit(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestBody Map<String, Object> request) {
        String txId = request.get("requestId") != null 
                ? request.get("requestId").toString() 
                : "tx-" + UUID.randomUUID().toString();
        log.info("Khởi tạo transfer 2 bước: txId={}, userId={}", txId, headerUserId);
        
        Map<String, Object> transferData = new LinkedHashMap<>(request);
        transferData.put("transferId", txId);
        transferData.put("transactionId", txId);
        transferData.put("status", "PENDING_CONFIRMATION");
        transferData.put("userId", headerUserId);
        pendingTransfers.put(txId, transferData);

        return ResponseEntity.ok(ApiResponse.success("Khởi tạo chuyển tiền thành công", transferData));
    }

    @PostMapping("/transfer/{id}/confirm")
    public ResponseEntity<ApiResponse<Map<String, Object>>> transferConfirm(
            @PathVariable("id") String id,
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestParam(value = "pin", required = false) String pin,
            @RequestParam(value = "otp", required = false) String otp,
            @RequestBody(required = false) Map<String, Object> body) {
        log.info("Xác nhận transfer 2 bước: txId={}, userId={}", id, headerUserId);
        Map<String, Object> transferData = pendingTransfers.getOrDefault(id, new LinkedHashMap<>());
        transferData.put("transferId", id);
        transferData.put("transactionId", id);
        transferData.put("status", "SUCCESS");
        return ResponseEntity.ok(ApiResponse.success("Xác nhận chuyển tiền thành công", transferData));
    }
}

