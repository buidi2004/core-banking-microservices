package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationUseCase notificationUseCase;

    public NotificationController(NotificationUseCase notificationUseCase) {
        this.notificationUseCase = notificationUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationInfo>>> getNotifications(
            Authentication auth,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        String userId = auth.getName();
        List<NotificationInfo> notifications = notificationUseCase.getNotifications(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Notifications retrieved", notifications));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(Authentication auth, @PathVariable String id) {
        String userId = auth.getName();
        notificationUseCase.markAsRead(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Notification marked as read", null));
    }

    @PutMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(Authentication auth) {
        String userId = auth.getName();
        notificationUseCase.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    @PostMapping("/devices")
    public ResponseEntity<ApiResponse<DeviceToken>> registerDeviceToken(
            Authentication auth,
            @RequestParam String deviceId,
            @RequestParam String fcmToken) {
        String userId = auth.getName();
        DeviceToken token = notificationUseCase.registerDeviceToken(userId, deviceId, fcmToken);
        return ResponseEntity.ok(ApiResponse.success("FCM device token registered", token));
    }

    @DeleteMapping("/devices/{deviceId}")
    public ResponseEntity<ApiResponse<Void>> unregisterDeviceToken(Authentication auth, @PathVariable String deviceId) {
        String userId = auth.getName();
        notificationUseCase.unregisterDeviceToken(userId, deviceId);
        return ResponseEntity.ok(ApiResponse.success("FCM device token unregistered", null));
    }

    @PutMapping("/settings")
    public ResponseEntity<ApiResponse<Void>> updateSettings(
            Authentication auth,
            @RequestParam boolean transactionEnabled,
            @RequestParam boolean promoEnabled) {
        String userId = auth.getName();
        notificationUseCase.updateSettings(userId, transactionEnabled, promoEnabled);
        return ResponseEntity.ok(ApiResponse.success("Notification settings updated", null));
    }
}
