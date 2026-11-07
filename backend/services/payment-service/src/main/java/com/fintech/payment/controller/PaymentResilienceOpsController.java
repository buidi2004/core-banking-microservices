package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.resilience.ResilienceDashboardResponse;
import com.fintech.payment.service.ResilienceOpsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/payments/ops")
@RequiredArgsConstructor
public class PaymentResilienceOpsController {

    private final ResilienceOpsService resilienceOpsService;

    @GetMapping("/resilience")
    public ResponseEntity<ApiResponse<ResilienceDashboardResponse>> getResilienceDashboard(
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireStaff(role);
        ResilienceDashboardResponse response = resilienceOpsService.getResilienceDashboard();
        return ResponseEntity.ok(ApiResponse.success("Báo cáo sức khỏe & khả năng phục hồi hệ thống", response));
    }

    private void requireStaff(String role) {
        if (role == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Thiếu vai trò người dùng (X-User-Role).");
        }
        String r = role.toUpperCase();
        if (!r.contains("TELLER") && !r.contains("MANAGER") && !r.contains("ADMIN")) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ cán bộ nhân viên mới có quyền xem thông tin Resilience Dashboard.");
        }
    }
}

