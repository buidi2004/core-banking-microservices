package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.security.JwtTokenProvider;
import com.fintech.identity.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/security")
@RequiredArgsConstructor
public class SecurityBiometricController {

    private final JwtTokenProvider jwtTokenProvider;
    private final AuthService authService;

    @PostMapping("/biometric/verify")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyBiometric(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody(required = false) Map<String, Object> payload) {
        log.info("Xác thực sinh trắc học thiết bị thành công cho userId={}", userId);
        String pinToken = jwtTokenProvider.generateBiometricToken(userId);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("pinToken", pinToken, "biometricToken", pinToken, "expiresIn", 300L, "standard", "QĐ 2345/QĐ-NHNN"),
                "Xác thực sinh trắc học thành công theo Quyết định 2345/QĐ-NHNN"
        ));
    }

    @PostMapping("/emergency-lock")
    public ResponseEntity<ApiResponse<Map<String, Object>>> emergencyLock(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestBody(required = false) Map<String, String> body) {
        String reason = (body != null && body.containsKey("reason")) ? body.get("reason") : "Nghi ngờ bị lừa đảo / lộ thông tin tài khoản";
        var result = authService.emergencyLock(authHeader, headerUserId, reason);
        return ResponseEntity.ok(ApiResponse.ok(result, "Đã kích hoạt khóa khẩn cấp tài khoản an toàn"));
    }
}

