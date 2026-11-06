package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.CreateScheduledTransferRequest;
import com.fintech.payment.dto.ScheduledTransferResponse;
import com.fintech.payment.service.ScheduledTransferService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/payments/scheduled-transfers")
@RequiredArgsConstructor
public class ScheduledTransferController {

    private final ScheduledTransferService scheduledTransferService;

    @PostMapping
    public ResponseEntity<ApiResponse<ScheduledTransferResponse>> createSchedule(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @Valid @RequestBody CreateScheduledTransferRequest request) {
        ScheduledTransferResponse response = scheduledTransferService.createSchedule(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Lập lịch chuyển tiền thành công", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ScheduledTransferResponse>>> getMySchedules(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId) {
        List<ScheduledTransferResponse> list = scheduledTransferService.getUserSchedules(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách lệnh chuyển tiền đặt lịch", list));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<ScheduledTransferResponse>> cancelSchedule(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id) {
        ScheduledTransferResponse response = scheduledTransferService.cancelSchedule(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Hủy lệnh chuyển tiền đặt lịch thành công", response));
    }

    @PostMapping("/execute-due")
    public ResponseEntity<ApiResponse<Map<String, Object>>> executeDue(
            @RequestHeader(value = "X-User-Role", required = false) String userRole) {
        if (!isManager(userRole)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("Chỉ ROLE_MANAGER mới được thực thi lệnh chuyển tiền đến hạn"));
        }
        Map<String, Object> summary = scheduledTransferService.executeDueSchedules();
        return ResponseEntity.ok(ApiResponse.success("Quét và thực thi các lệnh chuyển tiền đến hạn", summary));
    }

    private boolean isManager(String role) {
        return role != null
                && ("ROLE_MANAGER".equalsIgnoreCase(role.trim()) || "MANAGER".equalsIgnoreCase(role.trim()));
    }
}
