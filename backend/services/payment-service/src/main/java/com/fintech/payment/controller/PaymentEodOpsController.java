package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.eod.PaymentEodGateResponse;
import com.fintech.payment.service.PaymentEodOpsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/payments/ops")
@RequiredArgsConstructor
public class PaymentEodOpsController {

    private final PaymentEodOpsService paymentEodOpsService;

    @GetMapping("/eod-gate")
    public ResponseEntity<ApiResponse<PaymentEodGateResponse>> checkEodGate(
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        PaymentEodGateResponse response = paymentEodOpsService.checkEodGate();
        return ResponseEntity.ok(ApiResponse.success("Kiểm tra điều kiện EOD Gate thành công", response));
    }

    @PostMapping("/outbox/drain")
    public ResponseEntity<ApiResponse<Map<String, Object>>> drainOutbox(
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        long remaining = paymentEodOpsService.drainOutbox();
        return ResponseEntity.ok(ApiResponse.success("Outbox drain executed", Map.of(
                "remainingPending", remaining,
                "drained", remaining == 0
        )));
    }

    private void requireManager(String role) {
        if (role == null || (!"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim())
                && !"ROLE_ADMIN".equalsIgnoreCase(role.trim())
                && !"ADMIN".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Quản lý (ROLE_MANAGER/ADMIN) mới có quyền truy cập EOD Gate.");
        }
    }
}
