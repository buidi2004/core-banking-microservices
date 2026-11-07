package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.UpdateProfileRequest;
import com.fintech.identity.dto.UserProfileResponse;
import com.fintech.identity.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller quản lý thông tin người dùng.
 * Nhận diện người dùng trực tiếp qua header tin cậy 'X-User-Id' do API Gateway inject.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping({"/me", "/profile"})
    public ResponseEntity<ApiResponse<UserProfileResponse>> getCurrentUser(
            @RequestHeader(value = "X-User-Id") String userId) {
        log.debug("Lấy thông tin người dùng hiện tại từ header X-User-Id={}", userId);
        UserProfileResponse response = userService.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping({"/profile", "/me"})
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @RequestHeader(value = "X-User-Id") String userId,
            @RequestBody UpdateProfileRequest request) {
        log.info("Cập nhật thông tin cho X-User-Id={}", userId);
        UserProfileResponse response = userService.updateProfile(userId, request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật hồ sơ thành công"));
    }

    @PostMapping("/me/avatar")
    public ResponseEntity<ApiResponse<UserProfileResponse>> uploadAvatar(
            @RequestHeader(value = "X-User-Id") String userId,
            @RequestBody java.util.Map<String, String> payload) {
        String avatarUrl = payload.getOrDefault("avatarUrl", payload.get("url"));
        UpdateProfileRequest req = UpdateProfileRequest.builder().avatarUrl(avatarUrl).build();
        UserProfileResponse response = userService.updateProfile(userId, req);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật ảnh đại diện thành công"));
    }

    @PutMapping("/me/alias")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> setAccountAlias(
            @RequestHeader(value = "X-User-Id") String userId,
            @RequestParam(required = false) String alias,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        String targetAlias = (alias != null && !alias.isBlank()) ? alias
                : (body != null ? (body.get("alias") != null ? body.get("alias") : body.get("accountAlias")) : null);
        if (targetAlias == null || targetAlias.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Biệt danh tài khoản không được để trống"));
        }
        String cleanAlias = targetAlias.trim().toUpperCase();
        if (cleanAlias.length() < 3 || cleanAlias.length() > 30) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Biệt danh tài khoản phải từ 3 đến 30 ký tự"));
        }
        if (!cleanAlias.matches("^[A-Z0-9._-]+$")) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Biệt danh chỉ bao gồm chữ cái in hoa không dấu, chữ số và dấu . _ -"));
        }
        try {
            userService.setAccountAlias(userId, cleanAlias);
            return ResponseEntity.ok(ApiResponse.ok(java.util.Map.of("userId", userId, "accountAlias", cleanAlias), "Thiết lập biệt danh tài khoản nhận tiền thành công"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
