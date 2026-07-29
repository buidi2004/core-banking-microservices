package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.in.KycUseCase;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.presentation.request.KycSubmitRequest;
import com.fintech.wallet.presentation.request.SetPinRequest;
import com.fintech.wallet.presentation.request.VerifyPinRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.KycResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final PinUseCase pinUseCase;
    private final KycUseCase kycUseCase;

    public UserController(PinUseCase pinUseCase, KycUseCase kycUseCase) {
        this.pinUseCase = pinUseCase;
        this.kycUseCase = kycUseCase;
    }

    @PostMapping("/pin/set")
    public ResponseEntity<ApiResponse<Void>> setPin(Authentication auth, @Valid @RequestBody SetPinRequest request) {
        String userId = auth.getName();
        pinUseCase.setPin(userId, request.getPin());
        return ResponseEntity.ok(ApiResponse.success("Transaction PIN set successfully", null));
    }

    @PostMapping("/pin/verify")
    public ResponseEntity<ApiResponse<String>> verifyPin(Authentication auth, @Valid @RequestBody VerifyPinRequest request) {
        String userId = auth.getName();
        String pinToken = pinUseCase.verifyPinAndIssueToken(userId, request.getPin());
        return ResponseEntity.ok(ApiResponse.success("PIN verified successfully", pinToken));
    }

    @PostMapping("/kyc")
    public ResponseEntity<ApiResponse<KycResponse>> submitKyc(Authentication auth, @Valid @RequestBody KycSubmitRequest request) {
        String userId = auth.getName();
        UserKyc kyc = kycUseCase.submitKyc(
                userId,
                request.getIdCardNumber(),
                request.getFullName(),
                request.getDob(),
                request.getFrontCardUrl(),
                request.getBackCardUrl(),
                request.getSelfieUrl()
        );
        KycResponse response = KycResponse.fromDomain(kyc);
        return ResponseEntity.ok(ApiResponse.success("KYC submitted successfully", response));
    }

    @GetMapping("/kyc/status")
    public ResponseEntity<ApiResponse<KycResponse>> getKycStatus(Authentication auth) {
        String userId = auth.getName();
        UserKyc kyc = kycUseCase.getKycStatus(userId);
        KycResponse response = KycResponse.fromDomain(kyc);
        return ResponseEntity.ok(ApiResponse.success("KYC status retrieved", response));
    }

    @PostMapping("/kyc/webhook")
    public ResponseEntity<ApiResponse<KycResponse>> kycWebhook(@RequestParam String userId,
                                                               @RequestParam com.fintech.wallet.domain.model.KycStatus status,
                                                               @RequestParam(required = false) String reason) {
        UserKyc updatedKyc = kycUseCase.processKycWebhook(userId, status, reason);
        return ResponseEntity.ok(ApiResponse.success("KYC status updated via webhook", KycResponse.fromDomain(updatedKyc)));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(Authentication auth,
                                                             @RequestParam String oldPassword,
                                                             @RequestParam String newPassword) {
        String userId = auth.getName();
        if (kycUseCase instanceof com.fintech.wallet.application.service.UserService userService) {
            userService.changePassword(userId, oldPassword, newPassword);
        }
        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", null));
    }
}
