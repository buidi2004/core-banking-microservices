package com.fintech.notification.controller;

import com.fintech.notification.dto.ApiResponse;
import com.fintech.notification.entity.Promotion;
import com.fintech.notification.entity.Voucher;
import com.fintech.notification.service.PromotionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/promotions")
public class PromotionController {

    private final PromotionService promotionService;

    public PromotionController(PromotionService promotionService) {
        this.promotionService = promotionService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Voucher>>> getActivePromotions() {
        return ResponseEntity.ok(ApiResponse.success("Active promotions retrieved",
                promotionService.getActivePromotions()));
    }

    @GetMapping("/campaigns")
    public ResponseEntity<ApiResponse<List<Promotion>>> getActiveCampaigns() {
        return ResponseEntity.ok(ApiResponse.success("Active campaigns retrieved",
                promotionService.getActiveCampaigns()));
    }

    @PostMapping("/redeem")
    public ResponseEntity<ApiResponse<Voucher>> redeemVoucher(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam String code) {
        String uid = requireUser(userId);
        return ResponseEntity.ok(ApiResponse.success("Voucher redeemed successfully",
                promotionService.redeemVoucher(uid, code)));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<Voucher>> applyVoucher(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam String code,
            @RequestParam BigDecimal orderAmount) {
        String uid = requireUser(userId);
        return ResponseEntity.ok(ApiResponse.success("Voucher applied successfully",
                promotionService.applyVoucher(uid, code, orderAmount)));
    }

    @GetMapping("/my-vouchers")
    public ResponseEntity<ApiResponse<List<Voucher>>> getMyVouchers(
            @RequestHeader(name = "X-User-Id", required = false) String userId) {
        String uid = requireUser(userId);
        return ResponseEntity.ok(ApiResponse.success("User vouchers retrieved",
                promotionService.getMyVouchers(uid)));
    }

    private String requireUser(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("Missing trusted header X-User-Id");
        }
        return userId;
    }
}
