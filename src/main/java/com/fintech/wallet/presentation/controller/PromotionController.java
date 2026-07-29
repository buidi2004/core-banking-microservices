package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Voucher;
import com.fintech.wallet.domain.port.in.PromotionUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/promotions")
public class PromotionController {

    private final PromotionUseCase promotionUseCase;

    public PromotionController(PromotionUseCase promotionUseCase) {
        this.promotionUseCase = promotionUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Voucher>>> getActivePromotions() {
        List<Voucher> vouchers = promotionUseCase.getActivePromotions();
        return ResponseEntity.ok(ApiResponse.success("Active promotions retrieved", vouchers));
    }

    @PostMapping("/redeem")
    public ResponseEntity<ApiResponse<Voucher>> redeemVoucher(Authentication auth, @RequestParam String code) {
        String userId = auth.getName();
        Voucher voucher = promotionUseCase.redeemVoucher(userId, code);
        return ResponseEntity.ok(ApiResponse.success("Voucher redeemed successfully", voucher));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<Voucher>> applyVoucher(
            Authentication auth,
            @RequestParam String code,
            @RequestParam BigDecimal orderAmount) {
        String userId = auth.getName();
        Voucher voucher = promotionUseCase.applyVoucher(userId, code, orderAmount);
        return ResponseEntity.ok(ApiResponse.success("Voucher applied successfully", voucher));
    }

    @GetMapping("/my-vouchers")
    public ResponseEntity<ApiResponse<List<Voucher>>> getMyVouchers(Authentication auth) {
        String userId = auth.getName();
        List<Voucher> vouchers = promotionUseCase.getMyVouchers(userId);
        return ResponseEntity.ok(ApiResponse.success("User vouchers retrieved", vouchers));
    }
}
