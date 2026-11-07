package com.fintech.notification.controller;

import com.fintech.notification.dto.ApiResponse;
import com.fintech.notification.dto.TestPushRequest;
import com.fintech.notification.service.NotificationOpsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications/ops")
@RequiredArgsConstructor
public class NotificationOpsController {

    private final NotificationOpsService opsService;

    @GetMapping("/dlq/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDlqStats(
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        return ResponseEntity.ok(ApiResponse.success("DLQ stats retrieved", opsService.getDlqStats()));
    }

    @PostMapping("/dlq/retry")
    public ResponseEntity<ApiResponse<Map<String, Object>>> retryDlq(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @RequestParam(defaultValue = "50") int maxMessages) {
        requireManager(role);
        requireUser(actorId);
        return ResponseEntity.ok(ApiResponse.success("DLQ messages retried",
                opsService.retryDlqMessages(maxMessages, actorId)));
    }

    @PostMapping("/dlq/purge")
    public ResponseEntity<ApiResponse<Map<String, Object>>> purgeDlq(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        requireUser(actorId);
        return ResponseEntity.ok(ApiResponse.success("DLQ purged", opsService.purgeDlq(actorId)));
    }

    @GetMapping("/providers/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProviderHealth(
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        return ResponseEntity.ok(ApiResponse.success("Notification providers health retrieved",
                opsService.getProviderHealth()));
    }

    @PostMapping("/test-push")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testPush(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody TestPushRequest request) {
        requireManager(role);
        requireUser(actorId);
        return ResponseEntity.ok(ApiResponse.success("Test notification sent",
                opsService.sendTestNotification(request, actorId)));
    }

    private void requireUser(String id) {
        if (id == null || id.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing trusted user header");
        }
    }

    private void requireManager(String role) {
        if (role == null || (!"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim())
                && !"ROLE_ADMIN".equalsIgnoreCase(role.trim())
                && !"ADMIN".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Quản lý (ROLE_MANAGER/ADMIN) mới có quyền truy cập Notification Ops.");
        }
    }
}
