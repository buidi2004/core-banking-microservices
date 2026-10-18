package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.KycResponse;
import com.fintech.identity.dto.KycSubmitRequest;
import com.fintech.identity.service.KycService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller xử lý hồ sơ eKYC xác minh danh tính.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/kyc")
@RequiredArgsConstructor
public class KycController {

    private final KycService kycService;

    @PostMapping("/submit")
    public ResponseEntity<ApiResponse<KycResponse>> submitKyc(
            @RequestHeader(value = "X-User-Id") String userId,
            @Valid @RequestBody KycSubmitRequest request) {
        log.info("Nhận hồ sơ eKYC từ X-User-Id={}", userId);
        KycResponse response = kycService.submitKyc(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Gửi hồ sơ eKYC thành công, vui lòng chờ duyệt"));
    }

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<KycResponse>> getKycStatus(
            @RequestHeader(value = "X-User-Id") String userId) {
        KycResponse response = kycService.getKycStatus(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/{kycId}/review")
    public ResponseEntity<ApiResponse<KycResponse>> reviewKyc(
            @PathVariable String kycId,
            @RequestParam String status, // APPROVED hoặc REJECTED
            @RequestParam(required = false) String reason,
            @RequestHeader(value = "X-User-Id", required = false) String adminId) {
        log.info("Admin {} đánh giá hồ sơ eKYC kycId={}: status={}", adminId, kycId, status);
        KycResponse response = kycService.reviewKyc(kycId, status, reason, adminId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Đã cập nhật trạng thái duyệt eKYC"));
    }
}
