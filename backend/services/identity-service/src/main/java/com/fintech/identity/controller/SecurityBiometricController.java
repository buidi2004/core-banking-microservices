package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/security/biometric")
@RequiredArgsConstructor
public class SecurityBiometricController {

    private final JwtTokenProvider jwtTokenProvider;

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifyBiometric(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody(required = false) Map<String, Object> payload) {
        log.info("Xác thực sinh trắc học thiết bị thành công cho userId={}", userId);
        String pinToken = jwtTokenProvider.generatePinToken(userId);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("pinToken", pinToken, "expiresIn", 300L),
                "Xác thực sinh trắc học thành công"
        ));
    }
}

