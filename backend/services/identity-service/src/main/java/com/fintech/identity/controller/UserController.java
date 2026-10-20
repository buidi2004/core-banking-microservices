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

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getCurrentUser(
            @RequestHeader(value = "X-User-Id") String userId) {
        log.debug("Lấy thông tin người dùng hiện tại từ header X-User-Id={}", userId);
        UserProfileResponse response = userService.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @RequestHeader(value = "X-User-Id") String userId,
            @RequestBody UpdateProfileRequest request) {
        log.info("Cập nhật thông tin cho X-User-Id={}", userId);
        UserProfileResponse response = userService.updateProfile(userId, request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật hồ sơ thành công"));
    }
}
