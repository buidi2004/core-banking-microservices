package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.SessionResponse;
import com.fintech.identity.service.SessionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller quản lý phiên đăng nhập các thiết bị.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<SessionResponse>>> getActiveSessions(
            @RequestHeader(value = "X-User-Id") String userId,
            @RequestHeader(value = "X-Device-Id", required = false) String currentDeviceId) {
        log.debug("Lấy danh sách phiên đăng nhập của X-User-Id={}", userId);
        List<SessionResponse> sessions = sessionService.getUserSessions(userId, currentDeviceId);
        return ResponseEntity.ok(ApiResponse.ok(sessions));
    }

    @DeleteMapping("/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> revokeSession(
            @RequestHeader(value = "X-User-Id") String userId,
            @PathVariable String sessionId) {
        log.info("X-User-Id={} yêu cầu thu hồi phiên sessionId={}", userId, sessionId);
        sessionService.revokeSession(userId, sessionId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đã thu hồi phiên đăng nhập thiết bị"));
    }

    @PostMapping("/{deviceId}/fcm")
    public ResponseEntity<ApiResponse<Void>> registerFcm(
            @RequestHeader(value = "X-User-Id") String userId,
            @PathVariable String deviceId,
            @RequestBody(required = false) java.util.Map<String, String> payload) {
        log.info("Cập nhật FCM token cho deviceId={} của userId={}", deviceId, userId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đăng ký nhận thông báo đẩy thành công"));
    }
}
