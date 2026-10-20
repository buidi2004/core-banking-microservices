package com.fintech.identity.controller;

import com.fintech.identity.dto.*;
import com.fintech.identity.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final com.fintech.identity.service.OtpService otpService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        log.info("Nhận yêu cầu đăng ký tài khoản cho SĐT: {}", request.getPhoneNumber());
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Đăng ký tài khoản thành công"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request,
                                                           HttpServletRequest httpRequest) {
        String ipAddress = getClientIp(httpRequest);
        String userAgent = httpRequest.getHeader(HttpHeaders.USER_AGENT);

        log.info("Nhận yêu cầu đăng nhập từ tài khoản: {}, IP: {}", request.getIdentifier(), ipAddress);
        AuthResponse response = authService.login(request, ipAddress, userAgent);
        return ResponseEntity.ok(ApiResponse.ok(response, "Đăng nhập thành công"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Làm mới token thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authHeader,
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestParam(value = "deviceId", required = false) String deviceId) {
        authService.logout(authHeader, userId, deviceId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đăng xuất thành công"));
    }

    @PostMapping("/otp/send")
    public ResponseEntity<ApiResponse<OtpSendResponse>> sendOtp(
            @RequestBody(required = false) OtpSendRequest request,
            @RequestParam(required = false) String phoneNumber,
            @RequestParam(required = false) String purpose) {
        String phone = (request != null && request.getPhoneNumber() != null) ? request.getPhoneNumber() : phoneNumber;
        String purp = (request != null && request.getPurpose() != null) ? request.getPurpose() : purpose;
        if (phone == null || phone.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Số điện thoại không được để trống"));
        }
        OtpSendResponse response = otpService.sendOtp(phone, purp);
        return ResponseEntity.ok(ApiResponse.ok(response, response.getMessage()));
    }

    @PostMapping("/otp/verify")
    public ResponseEntity<ApiResponse<OtpVerifyResponse>> verifyOtp(
            @RequestBody(required = false) OtpVerifyRequest request,
            @RequestParam(required = false) String phoneNumber,
            @RequestParam(required = false) String otp,
            @RequestParam(required = false) String code,
            @RequestParam(required = false) String purpose) {
        String phone = (request != null && request.getPhoneNumber() != null) ? request.getPhoneNumber() : phoneNumber;
        String otpCode = (request != null && request.getCode() != null) ? request.getCode() : (otp != null ? otp : code);
        String purp = (request != null && request.getPurpose() != null) ? request.getPurpose() : purpose;
        if (phone == null || otpCode == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Thiếu số điện thoại hoặc mã OTP"));
        }
        OtpVerifyResponse response = otpService.verifyOtp(phone, otpCode, purp);
        return ResponseEntity.ok(ApiResponse.ok(response, response.getMessage()));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<OtpSendResponse>> forgotPassword(
            @RequestBody(required = false) ForgotPasswordRequest request,
            @RequestParam(required = false) String phoneNumber) {
        String phone = (request != null && request.getPhoneNumber() != null) ? request.getPhoneNumber() : phoneNumber;
        if (phone == null || phone.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Số điện thoại không được để trống"));
        }
        OtpSendResponse response = otpService.forgotPassword(phone);
        return ResponseEntity.ok(ApiResponse.ok(response, response.getMessage()));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @RequestBody(required = false) ResetPasswordRequest request,
            @RequestParam(required = false) String phoneNumber,
            @RequestParam(required = false) String otp,
            @RequestParam(required = false) String otpToken,
            @RequestParam(required = false) String newPassword) {
        String phone = (request != null && request.getPhoneNumber() != null) ? request.getPhoneNumber() : phoneNumber;
        String token = (request != null && request.getOtpToken() != null) ? request.getOtpToken() : (otpToken != null ? otpToken : otp);
        String newPass = (request != null && request.getNewPassword() != null) ? request.getNewPassword() : newPassword;
        if (phone == null || token == null || newPass == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Thiếu thông tin đặt lại mật khẩu"));
        }
        otpService.resetPassword(phone, token, newPass);
        return ResponseEntity.ok(ApiResponse.ok(null, "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."));
    }

    private String getClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
