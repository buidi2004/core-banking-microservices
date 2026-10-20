package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.PinSetRequest;
import com.fintech.identity.dto.PinVerifyRequest;
import com.fintech.identity.dto.PinVerifyResponse;
import com.fintech.identity.service.UserPinService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/users/pin")
@RequiredArgsConstructor
public class UserPinController {

    private final UserPinService userPinService;

    @PostMapping("/set")
    public ResponseEntity<ApiResponse<Void>> setPin(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody PinSetRequest request) {
        log.info("Thiết lập mã PIN cho người dùng X-User-Id={}", userId);
        userPinService.setPin(userId, request.getPin());
        return ResponseEntity.ok(ApiResponse.ok(null, "Thiết lập mã PIN giao dịch thành công"));
    }

    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<String>> verifyPin(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody PinVerifyRequest request) {
        log.debug("Xác thực mã PIN cho người dùng X-User-Id={}", userId);
        PinVerifyResponse response = userPinService.verifyPin(userId, request.getPin());
        return ResponseEntity.ok(ApiResponse.ok(response.getPinToken(), "Xác thực mã PIN thành công"));
    }
}

