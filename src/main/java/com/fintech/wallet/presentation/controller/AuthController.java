package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.presentation.request.LoginRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.AuthResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthUseCase authUseCase;

    public AuthController(AuthUseCase authUseCase) {
        this.authUseCase = authUseCase;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        User user = authUseCase.register(request.getPhoneNumber(), request.getPassword());
        String token = authUseCase.login(request.getPhoneNumber(), request.getPassword());
        AuthResponse response = new AuthResponse(user.getId(), token);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User registered successfully", response));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        String token = authUseCase.login(request.getPhoneNumber(), request.getPassword());
        AuthResponse response = new AuthResponse(null, token);
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    @PostMapping("/otp/send")
    public ResponseEntity<ApiResponse<Void>> sendOtp(@RequestParam String phoneNumber) {
        authUseCase.sendOtp(phoneNumber);
        return ResponseEntity.ok(ApiResponse.success("OTP sent successfully", null));
    }

    @PostMapping("/otp/verify")
    public ResponseEntity<ApiResponse<Boolean>> verifyOtp(@RequestParam String phoneNumber, @RequestParam String otp) {
        boolean verified = authUseCase.verifyOtp(phoneNumber, otp);
        return ResponseEntity.ok(ApiResponse.success("OTP verification result", verified));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<String>> refreshToken(@RequestParam String refreshToken) {
        String newAccessToken = authUseCase.refreshToken(refreshToken);
        return ResponseEntity.ok(ApiResponse.success("Access token refreshed", newAccessToken));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@RequestParam String phoneNumber) {
        authUseCase.sendPasswordResetOtp(phoneNumber);
        return ResponseEntity.ok(ApiResponse.success("Password reset OTP sent to " + phoneNumber, null));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@RequestParam String phoneNumber,
                                                            @RequestParam String otp,
                                                            @RequestParam String newPassword) {
        authUseCase.resetPassword(phoneNumber, otp, newPassword);
        return ResponseEntity.ok(ApiResponse.success("Password reset successfully", null));
    }
}
