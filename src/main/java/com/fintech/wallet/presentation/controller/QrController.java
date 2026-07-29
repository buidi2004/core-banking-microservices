package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.PersonalQrUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping
public class QrController {

    private final PersonalQrUseCase personalQrUseCase;

    public QrController(PersonalQrUseCase personalQrUseCase) {
        this.personalQrUseCase = personalQrUseCase;
    }

    @GetMapping("/api/v1/users/me/qrcode")
    public ResponseEntity<ApiResponse<String>> getPersonalQrCode(Authentication auth) {
        String userId = auth.getName();
        String qrPayload = personalQrUseCase.getPersonalQrPayload(userId);
        return ResponseEntity.ok(ApiResponse.success("Personal wallet QR generated", qrPayload));
    }

    @PostMapping("/api/v1/payments/qr/scan")
    public ResponseEntity<ApiResponse<Map<String, Object>>> scanQr(@RequestParam String qrString) {
        Map<String, Object> result = personalQrUseCase.scanQr(qrString);
        return ResponseEntity.ok(ApiResponse.success("QR scanned and parsed successfully", result));
    }
}
