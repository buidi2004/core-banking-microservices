package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.SecurityUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping
public class SecurityController {

    private final SecurityUseCase securityUseCase;

    public SecurityController(SecurityUseCase securityUseCase) {
        this.securityUseCase = securityUseCase;
    }

    @PostMapping("/api/v1/security/biometric/register")
    public ResponseEntity<ApiResponse<Void>> registerBiometric(Authentication auth, @RequestParam String biometricToken) {
        String userId = auth.getName();
        securityUseCase.registerBiometric(userId, biometricToken);
        return ResponseEntity.ok(ApiResponse.success("Biometric registered successfully", null));
    }

    @PostMapping("/api/v1/security/biometric/verify")
    public ResponseEntity<ApiResponse<String>> verifyBiometric(Authentication auth, @RequestParam String biometricToken) {
        String userId = auth.getName();
        String pinToken = securityUseCase.verifyBiometric(userId, biometricToken);
        return ResponseEntity.ok(ApiResponse.success("Biometric verified successfully", pinToken));
    }

    @GetMapping("/api/v1/security/login-history")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getLoginHistory(Authentication auth) {
        String userId = auth.getName();
        List<Map<String, Object>> history = securityUseCase.getLoginHistory(userId);
        return ResponseEntity.ok(ApiResponse.success("Login history retrieved", history));
    }

    @PostMapping("/api/v1/account/2fa/enable")
    public ResponseEntity<ApiResponse<Void>> enable2FA(Authentication auth) {
        String userId = auth.getName();
        securityUseCase.enable2FA(userId);
        return ResponseEntity.ok(ApiResponse.success("2FA enabled successfully", null));
    }

    @PostMapping("/api/v1/account/2fa/disable")
    public ResponseEntity<ApiResponse<Void>> disable2FA(Authentication auth) {
        String userId = auth.getName();
        securityUseCase.disable2FA(userId);
        return ResponseEntity.ok(ApiResponse.success("2FA disabled successfully", null));
    }
}
