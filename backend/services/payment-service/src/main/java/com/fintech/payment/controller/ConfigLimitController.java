package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/config/limits")
public class ConfigLimitController {

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLimits() {
        List<Map<String, Object>> tiers = List.of(
                Map.of(
                        "tier", "BASIC",
                        "title", "Chưa định danh eKYC",
                        "maxPerTransaction", new BigDecimal("5000000"),
                        "maxDaily", new BigDecimal("20000000"),
                        "maxMonthly", new BigDecimal("100000000"),
                        "requirements", "Chỉ cần đăng ký số điện thoại"
                ),
                Map.of(
                        "tier", "VERIFIED",
                        "title", "Đã xác thực eKYC CCCD Chip",
                        "maxPerTransaction", new BigDecimal("100000000"),
                        "maxDaily", new BigDecimal("500000000"),
                        "maxMonthly", new BigDecimal("2000000000"),
                        "requirements", "Quét chip NFC căn cước công dân và xác thực khuôn mặt AI"
                ),
                Map.of(
                        "tier", "VIP",
                        "title", "Khách hàng ưu tiên Sen Hồng Private",
                        "maxPerTransaction", new BigDecimal("500000000"),
                        "maxDaily", new BigDecimal("2000000000"),
                        "maxMonthly", new BigDecimal("10000000000"),
                        "requirements", "Hạn mức tối đa theo thỏa thuận ngân hàng"
                )
        );

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("tiers", tiers);
        data.put("currency", "VND");
        data.put("standard", "Quyết định 2345/QĐ-NHNN về an toàn thanh toán trực tuyến");

        return ResponseEntity.ok(ApiResponse.success("Bảng định mức hạn mức giao dịch", data));
    }

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLimitStatus(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        // Mặc định khách hàng đã mở tài khoản thành công là VERIFIED tier
        BigDecimal maxPerTx = new BigDecimal("100000000");
        BigDecimal maxDaily = new BigDecimal("500000000");
        BigDecimal usedDaily = BigDecimal.ZERO;
        BigDecimal remainingDaily = maxDaily.subtract(usedDaily);

        BigDecimal maxMonthly = new BigDecimal("2000000000");
        BigDecimal usedMonthly = BigDecimal.ZERO;
        BigDecimal remainingMonthly = maxMonthly.subtract(usedMonthly);

        Map<String, Object> status = new LinkedHashMap<>();
        status.put("userId", userId);
        status.put("kycTier", "VERIFIED");
        status.put("tierTitle", "Khách hàng đã xác thực eKYC");
        status.put("maxPerTransaction", maxPerTx);
        status.put("maxDaily", maxDaily);
        status.put("usedDaily", usedDaily);
        status.put("remainingDaily", remainingDaily);
        status.put("maxMonthly", maxMonthly);
        status.put("usedMonthly", usedMonthly);
        status.put("remainingMonthly", remainingMonthly);
        status.put("currency", "VND");

        return ResponseEntity.ok(ApiResponse.success("Trạng thái hạn mức hiện tại", status));
    }
}

