package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/legal")
@RequiredArgsConstructor
public class LegalController {

    @GetMapping("/terms")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTerms() {
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "version", "2.4.0",
                "effectiveDate", "2026-07-01",
                "termsOfService", "Điều khoản và điều kiện sử dụng dịch vụ Ngân hàng điện tử Sen Hồng Bank tuân thủ theo Nghị định 52/2024/NĐ-CP và Quyết định 2345/QĐ-NHNN.",
                "privacyPolicy", "Chính sách bảo mật thông tin và dữ liệu cá nhân theo Nghị định 13/2023/NĐ-CP."
        )));
    }

    @PostMapping("/consent")
    public ResponseEntity<ApiResponse<Map<String, Object>>> recordConsent(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> payload) {
        log.info("User {} agreed to legal terms version {}", userId, payload.get("version"));
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("status", "CONSENTED", "recorded", true),
                "Đã ghi nhận sự đồng thuận của khách hàng"
        ));
    }
}

