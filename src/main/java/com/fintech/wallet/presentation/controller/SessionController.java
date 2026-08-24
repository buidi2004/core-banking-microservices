package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/sessions")
@Tag(name = "Session Management", description = "APIs for managing user sessions and devices")
public class SessionController {

    private final SessionManagementUseCase sessionManagementUseCase;

    public SessionController(SessionManagementUseCase sessionManagementUseCase) {
        this.sessionManagementUseCase = sessionManagementUseCase;
    }

    @Operation(summary = "Get active sessions")
    @GetMapping
    public ResponseEntity<ApiResponse<List<DeviceSession>>> getActiveSessions(Authentication auth) {
        String userId = auth.getName();
        List<DeviceSession> sessions = sessionManagementUseCase.getActiveSessions(userId);
        return ResponseEntity.ok(ApiResponse.success("Active sessions retrieved", sessions));
    }

    @Operation(summary = "Revoke a specific session (Remote Logout)")
    @DeleteMapping("/{deviceId}")
    public ResponseEntity<ApiResponse<Void>> revokeSession(Authentication auth, @PathVariable String deviceId) {
        String userId = auth.getName();
        sessionManagementUseCase.revokeSession(userId, deviceId);
        return ResponseEntity.ok(ApiResponse.success("Session revoked", null));
    }

    @Operation(summary = "Revoke all sessions")
    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> revokeAllSessions(Authentication auth) {
        String userId = auth.getName();
        sessionManagementUseCase.revokeAllSessions(userId);
        return ResponseEntity.ok(ApiResponse.success("All sessions revoked", null));
    }

    @Operation(summary = "Register FCM Token for device")
    @PostMapping("/{deviceId}/fcm")
    public ResponseEntity<ApiResponse<Void>> registerFcmToken(
            Authentication auth,
            @PathVariable String deviceId,
            @RequestParam String fcmToken) {
        String userId = auth.getName();
        sessionManagementUseCase.updateFcmToken(userId, deviceId, fcmToken);
        return ResponseEntity.ok(ApiResponse.success("FCM token registered", null));
    }
}
