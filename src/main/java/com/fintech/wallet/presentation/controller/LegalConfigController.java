package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.LegalConsent;
import com.fintech.wallet.domain.port.in.LegalConfigUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping
public class LegalConfigController {

    private final LegalConfigUseCase legalConfigUseCase;

    public LegalConfigController(LegalConfigUseCase legalConfigUseCase) {
        this.legalConfigUseCase = legalConfigUseCase;
    }

    @GetMapping("/api/v1/config/limits")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUserLimits(Authentication auth) {
        String userId = auth.getName();
        Map<String, Object> limits = legalConfigUseCase.getUserLimits(userId);
        return ResponseEntity.ok(ApiResponse.success("User transaction limits retrieved", limits));
    }

    @GetMapping("/api/v1/legal/terms")
    public ResponseEntity<ApiResponse<String>> getTermsOfService() {
        String terms = legalConfigUseCase.getTermsOfService();
        return ResponseEntity.ok(ApiResponse.success("Terms of service retrieved", terms));
    }

    @PostMapping("/api/v1/legal/consent")
    public ResponseEntity<ApiResponse<LegalConsent>> recordConsent(
            Authentication auth,
            @RequestParam String termsVersion,
            HttpServletRequest request) {
        String userId = auth.getName();
        String ip = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        LegalConsent consent = legalConfigUseCase.recordConsent(userId, termsVersion, ip, userAgent);
        return ResponseEntity.ok(ApiResponse.success("Legal consent recorded successfully", consent));
    }
}
