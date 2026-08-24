package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notification Center", description = "APIs for managing user notifications")
public class NotificationController {

    private final NotificationUseCase notificationUseCase;

    public NotificationController(NotificationUseCase notificationUseCase) {
        this.notificationUseCase = notificationUseCase;
    }

    @Operation(summary = "Get user notifications", description = "Returns a paginated list of notifications for the current user, optionally filtered by type.")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<NotificationInfo>>> getNotifications(
            Authentication auth,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        String userId = auth.getName();
        PageResponse<NotificationInfo> notifications = notificationUseCase.getNotifications(userId, type, page, size);
        return ResponseEntity.ok(ApiResponse.success("Notifications retrieved", notifications));
    }

    @Operation(summary = "Mark notification as read")
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(Authentication auth, @PathVariable String id) {
        String userId = auth.getName();
        notificationUseCase.markAsRead(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Notification marked as read", null));
    }

    @Operation(summary = "Mark all notifications as read", description = "Marks all notifications as read, optionally filtered by type.")
    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(Authentication auth, @RequestParam(required = false) String type) {
        String userId = auth.getName();
        notificationUseCase.markAllAsRead(userId, type);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
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
