package com.fintech.notification.controller;

import com.fintech.notification.dto.ApiResponse;
import com.fintech.notification.dto.RegisterDeviceTokenRequest;
import com.fintech.notification.entity.DeviceToken;
import com.fintech.notification.service.DeviceTokenService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/devices")
public class DeviceController {

    private final DeviceTokenService deviceTokenService;

    public DeviceController(DeviceTokenService deviceTokenService) {
        this.deviceTokenService = deviceTokenService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<DeviceToken>> registerDeviceToken(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @Valid @RequestBody RegisterDeviceTokenRequest request) {
        String uid = requireUser(userId);
        DeviceToken token = deviceTokenService.registerDeviceToken(uid, request.getFcmToken(),
                request.getDeviceType(), request.getDeviceModel(), request.getAppVersion());
        return ResponseEntity.ok(ApiResponse.success("Device token registered successfully", token));
    }

    @DeleteMapping("/unregister")
    public ResponseEntity<ApiResponse<Void>> unregisterDeviceToken(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam(name = "fcmToken", required = false) String fcmToken) {
        String uid = requireUser(userId);
        deviceTokenService.unregisterDeviceToken(uid, fcmToken);
        return ResponseEntity.ok(ApiResponse.success("Device token unregistered successfully", null));
    }

    private String requireUser(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("Missing trusted header X-User-Id");
        }
        return userId;
    }
}
