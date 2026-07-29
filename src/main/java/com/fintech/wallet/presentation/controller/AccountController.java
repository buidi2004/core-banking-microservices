package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.AccountUseCase;
import com.fintech.wallet.presentation.request.ChangePasswordRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/account")
public class AccountController {

    private final AccountUseCase accountUseCase;

    public AccountController(AccountUseCase accountUseCase) {
        this.accountUseCase = accountUseCase;
    }

    @PostMapping("/password/change")
    public ResponseEntity<ApiResponse<Void>> changePassword(Authentication auth, @Valid @RequestBody ChangePasswordRequest request) {
        String userId = auth.getName();
        accountUseCase.changePassword(userId, request.getOldPassword(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", null));
    }

    @PostMapping("/password/reset")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@RequestParam String phoneNumber,
                                                          @RequestParam String otp,
                                                          @RequestParam String newPassword) {
        accountUseCase.resetPassword(phoneNumber, otp, newPassword);
        return ResponseEntity.ok(ApiResponse.success("Password reset successfully", null));
    }
}
