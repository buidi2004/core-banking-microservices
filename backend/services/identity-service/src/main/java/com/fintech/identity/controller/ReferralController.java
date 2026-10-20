package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/referrals")
@RequiredArgsConstructor
public class ReferralController {

    @GetMapping("/code")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReferralCode(
            @RequestHeader("X-User-Id") String userId) {
        String code = "SEN" + Math.abs(userId.hashCode() % 900000 + 100000);
        String url = "https://senhongbank.com.vn/invite?code=" + code;
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "referralCode", code,
                "referralUrl", url,
                "rewardPerInvite", new BigDecimal("50000"),
                "rewardCurrency", "VND",
                "message", "Nhận ngay 50.000 VND khi bạn bè mở tài khoản thành công"
        )));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReferralHistory(
            @RequestHeader("X-User-Id") String userId) {
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "totalInvited", 0,
                "totalEarned", BigDecimal.ZERO,
                "pendingRewards", BigDecimal.ZERO,
                "invitedUsers", List.of()
        )));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<Map<String, Object>>> applyReferralCode(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, String> payload) {
        String code = payload.get("code");
        log.info("User {} applied referral code {}", userId, code);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("applied", true, "code", code, "bonus", new BigDecimal("50000")),
                "Áp dụng mã giới thiệu thành công"
        ));
    }
}

