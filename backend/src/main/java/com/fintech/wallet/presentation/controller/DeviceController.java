package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.in.DeviceTokenUseCase;
import com.fintech.wallet.presentation.request.RegisterDeviceTokenRequest;
import com.fintech.wallet.presentation.request.UnregisterDeviceTokenRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/devices")
@Tag(name = "Device Management", description = "APIs for registering and managing mobile device tokens for FCM Push Notifications")
public class DeviceController {

    private final DeviceTokenUseCase deviceTokenUseCase;

    public DeviceController(DeviceTokenUseCase deviceTokenUseCase) {
        this.deviceTokenUseCase = deviceTokenUseCase;
    }

    @Operation(summary = "Register FCM device token")
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<DeviceToken>> registerDeviceToken(
            Authentication auth,
            @Valid @RequestBody RegisterDeviceTokenRequest request) {
        String userId = auth.getName();
        DeviceToken token = deviceTokenUseCase.registerDeviceToken(userId, request.getFcmToken(), request.getDeviceType());
        return ResponseEntity.ok(ApiResponse.success("Device token registered successfully", token));
    }

    @Operation(summary = "Unregister FCM device token (logout)")
    @DeleteMapping("/unregister")
    public ResponseEntity<ApiResponse<Void>> unregisterDeviceToken(
            Authentication auth,
            @RequestParam(required = false) String fcmToken,
            @RequestBody(required = false) UnregisterDeviceTokenRequest request) {
        String userId = auth.getName();
        String tokenToDelete = fcmToken;
        if ((tokenToDelete == null || tokenToDelete.isBlank()) && request != null) {
            tokenToDelete = request.getFcmToken();
        }
        deviceTokenUseCase.unregisterDeviceToken(userId, tokenToDelete);
        return ResponseEntity.ok(ApiResponse.success("Device token unregistered successfully", null));
    }
}
