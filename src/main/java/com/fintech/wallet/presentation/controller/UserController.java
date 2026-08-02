package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.PublicUserProfile;
import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.in.AccountUseCase;
import com.fintech.wallet.domain.port.in.KycUseCase;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.presentation.request.KycSubmitRequest;
import com.fintech.wallet.presentation.request.SetPinRequest;
import com.fintech.wallet.presentation.request.VerifyPinRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.KycResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final PinUseCase pinUseCase;
    private final KycUseCase kycUseCase;
    private final AccountUseCase accountUseCase;

    public UserController(PinUseCase pinUseCase,
                          KycUseCase kycUseCase,
                          AccountUseCase accountUseCase) {
        this.pinUseCase    = pinUseCase;
        this.kycUseCase    = kycUseCase;
        this.accountUseCase = accountUseCase;
    }

    // ─── PIN ─────────────────────────────────────────────────────────────────

    @PostMapping("/pin/set")
    public ResponseEntity<ApiResponse<Void>> setPin(
            Authentication auth, @Valid @RequestBody SetPinRequest request) {
        pinUseCase.setPin(auth.getName(), request.getPin());
        return ResponseEntity.ok(ApiResponse.success("Transaction PIN set successfully", null));
    }

    @PostMapping("/pin/verify")
    public ResponseEntity<ApiResponse<String>> verifyPin(
            Authentication auth, @Valid @RequestBody VerifyPinRequest request) {
        String pinToken = pinUseCase.verifyPinAndIssueToken(auth.getName(), request.getPin());
        return ResponseEntity.ok(ApiResponse.success("PIN verified successfully", pinToken));
    }

    // ─── KYC ─────────────────────────────────────────────────────────────────

    @PostMapping("/kyc")
    public ResponseEntity<ApiResponse<KycResponse>> submitKyc(
            Authentication auth, @Valid @RequestBody KycSubmitRequest request) {
        UserKyc kyc = kycUseCase.submitKyc(
                auth.getName(),
                request.getIdCardNumber(), request.getFullName(), request.getDob(),
                request.getFrontCardUrl(), request.getBackCardUrl(), request.getSelfieUrl());
        return ResponseEntity.ok(ApiResponse.success("KYC submitted successfully", KycResponse.fromDomain(kyc)));
    }

    @GetMapping("/kyc/status")
    public ResponseEntity<ApiResponse<KycResponse>> getKycStatus(Authentication auth) {
        UserKyc kyc = kycUseCase.getKycStatus(auth.getName());
        return ResponseEntity.ok(ApiResponse.success("KYC status retrieved", KycResponse.fromDomain(kyc)));
    }

    @PostMapping("/kyc/webhook")
    public ResponseEntity<ApiResponse<KycResponse>> kycWebhook(
            @RequestParam String userId,
            @RequestParam com.fintech.wallet.domain.model.KycStatus status,
            @RequestParam(required = false) String reason) {
        UserKyc updatedKyc = kycUseCase.processKycWebhook(userId, status, reason);
        return ResponseEntity.ok(ApiResponse.success("KYC status updated via webhook",
                KycResponse.fromDomain(updatedKyc)));
    }

    // ─── Account ─────────────────────────────────────────────────────────────

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            Authentication auth,
            @RequestParam String oldPassword,
            @RequestParam String newPassword) {
        accountUseCase.changePassword(auth.getName(), oldPassword, newPassword);
        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", null));
    }

    /**
     * P2P recipient lookup by phone number.
     * Called when a sender types a phone number in the transfer screen.
     * Returns a masked public profile (userId + masked phone + KYC level).
     * Returns 404 when no account is found so the UI can show "User not found".
     *
     * GET /api/v1/users/search?phone=0987654321
     */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<PublicUserProfile>> searchByPhone(
            @RequestParam String phone) {
        Optional<PublicUserProfile> profile = accountUseCase.searchByPhone(phone);
        return profile
                .map(p -> ResponseEntity.ok(ApiResponse.success("User found", p)))
                .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error("No account registered for this phone number")));
    }
}
