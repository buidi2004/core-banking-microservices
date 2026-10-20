package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.VietQrService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payments/vietqr")
@RequiredArgsConstructor
public class VietQrController {

    private final VietQrService vietQrService;

    @PostMapping("/generate")
    public ResponseEntity<ApiResponse<VietQrResponse>> generateVietQr(@Valid @RequestBody VietQrGenerateRequest request) {
        VietQrResponse response = vietQrService.generateVietQr(request);
        return ResponseEntity.ok(ApiResponse.<VietQrResponse>builder()
                .success(true)
                .message("Sinh mã VietQR thành công")
                .data(response)
                .build());
    }

    @PostMapping("/decode")
    public ResponseEntity<ApiResponse<VietQrDecodeResponse>> decodeVietQr(
            @RequestBody(required = false) VietQrDecodeRequest request,
            @RequestParam(required = false) String qrString) {
        String raw = (request != null && request.getQrString() != null) ? request.getQrString() : qrString;
        if (raw == null || raw.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.<VietQrDecodeResponse>builder()
                    .success(false)
                    .message("Thiếu chuỗi mã QR")
                    .build());
        }
        VietQrDecodeResponse response = vietQrService.decodeVietQr(raw);
        return ResponseEntity.ok(ApiResponse.<VietQrDecodeResponse>builder()
                .success(true)
                .message("Giải mã VietQR thành công")
                .data(response)
                .build());
    }
}
