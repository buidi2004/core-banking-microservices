package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.ReferralInfo;
import com.fintech.wallet.domain.port.in.ReferralUseCase;
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
@RequestMapping("/api/v1/referrals")
public class ReferralController {

    private final ReferralUseCase referralUseCase;

    public ReferralController(ReferralUseCase referralUseCase) {
        this.referralUseCase = referralUseCase;
    }

    @GetMapping("/code")
    public ResponseEntity<ApiResponse<ReferralInfo>> getReferralCode(Authentication auth) {
        String userId = auth.getName();
        ReferralInfo info = referralUseCase.getReferralInfo(userId);
        return ResponseEntity.ok(ApiResponse.success("Referral info retrieved", info));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<Void>> applyReferralCode(Authentication auth, @RequestParam String referralCode) {
        String userId = auth.getName();
        referralUseCase.applyReferralCode(userId, referralCode);
        return ResponseEntity.ok(ApiResponse.success("Referral code applied successfully", null));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getReferralHistory(Authentication auth) {
        String userId = auth.getName();
        List<Map<String, Object>> history = referralUseCase.getReferralHistory(userId);
        return ResponseEntity.ok(ApiResponse.success("Referral history retrieved", history));
    }
}
