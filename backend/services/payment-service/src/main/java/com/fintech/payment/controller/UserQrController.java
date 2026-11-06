package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.VietQrResponse;
import com.fintech.payment.service.VietQrService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserQrController {

    private final VietQrService vietQrService;

    @GetMapping("/me/qrcode")
    public ResponseEntity<ApiResponse<VietQrResponse>> getMyQrCode(
            @RequestHeader(value = "X-User-Id", required = false) String userId,
            @RequestHeader(value = "X-User-Phone", required = false) String phone) {
        String identifier = (phone != null && !phone.isBlank()) ? phone : userId;
        if (identifier == null || identifier.isBlank()) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("UNAUTHORIZED", "Thiếu thông tin người dùng"));
        }
        VietQrResponse response = vietQrService.getUserQrCode(identifier);
        return ResponseEntity.ok(ApiResponse.<VietQrResponse>builder()
                .success(true)
                .message("Lấy mã QR cá nhân thành công")
                .data(response)
                .build());
    }
}

