package com.fintech.notification.controller;

import com.fintech.notification.dto.ApiResponse;
import com.fintech.notification.dto.PageResponse;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<Notification>>> getNotifications(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        String uid = requireUser(userId);
        PageResponse<Notification> notifications = notificationService.getNotifications(uid, type, page, size);
        return ResponseEntity.ok(ApiResponse.success("Notifications retrieved", notifications));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @RequestHeader(name = "X-User-Id", required = false) String userId) {
        String uid = requireUser(userId);
        return ResponseEntity.ok(ApiResponse.success("Unread count retrieved",
                Map.of("unread", notificationService.countUnread(uid))));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @PathVariable String id) {
        String uid = requireUser(userId);
        notificationService.markAsRead(uid, id);
        return ResponseEntity.ok(ApiResponse.success("Notification marked as read", null));
    }

    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam(required = false) String type) {
        String uid = requireUser(userId);
        notificationService.markAllAsRead(uid, type);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    @PutMapping("/settings")
    public ResponseEntity<ApiResponse<Void>> updateSettings(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam boolean transactionEnabled,
            @RequestParam boolean promoEnabled) {
        String uid = requireUser(userId);
        notificationService.updateSettings(uid, transactionEnabled, promoEnabled);
        return ResponseEntity.ok(ApiResponse.success("Notification settings updated", null));
    }

    private String requireUser(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("Missing trusted header X-User-Id");
        }
        return userId;
    }
}
