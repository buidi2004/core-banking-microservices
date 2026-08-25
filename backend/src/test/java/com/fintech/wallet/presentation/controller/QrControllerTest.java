package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.PersonalQrUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests cho QrController — tầng Presentation.
 *
 * Luồng được kiểm tra:
 *   GET  /api/v1/users/me/qrcode     → sinh QR ví cá nhân theo userId từ JWT
 *   POST /api/v1/payments/qr/scan    → scan QR → nhận diện loại giao dịch
 */
class QrControllerTest {

    @Mock
    private PersonalQrUseCase personalQrUseCase;

    @Mock
    private Authentication auth;

    @InjectMocks
    private QrController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(auth.getName()).thenReturn("user-123");
    }

    // ─── GET /api/v1/users/me/qrcode ─────────────────────────────────────────

    @Test
    void getPersonalQrCode_shouldReturn200WithQrPayload() {
        when(personalQrUseCase.getPersonalQrPayload("user-123"))
                .thenReturn("WALLET_QR:v1:user:user-123");

        ResponseEntity<ApiResponse<String>> response = target.getPersonalQrCode(auth);

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("WALLET_QR:v1:user:user-123", response.getBody().getData());
    }

    @Test
    void getPersonalQrCode_shouldUseUserIdFromAuthentication() {
        when(personalQrUseCase.getPersonalQrPayload(any())).thenReturn("WALLET_QR:v1:user:user-123");

        target.getPersonalQrCode(auth);

        // Must pass the authenticated user's ID — not a hardcoded value
        verify(personalQrUseCase).getPersonalQrPayload("user-123");
    }

    @Test
    void getPersonalQrCode_differentUsers_shouldCallUseCaseWithCorrectId() {
        Authentication otherAuth = mock(Authentication.class);
        when(otherAuth.getName()).thenReturn("user-456");
        when(personalQrUseCase.getPersonalQrPayload("user-456"))
                .thenReturn("WALLET_QR:v1:user:user-456");

        ResponseEntity<ApiResponse<String>> response = target.getPersonalQrCode(otherAuth);

        assertEquals("WALLET_QR:v1:user:user-456", response.getBody().getData());
        verify(personalQrUseCase).getPersonalQrPayload("user-456");
    }

    // ─── POST /api/v1/payments/qr/scan — WALLET_TRANSFER ────────────────────

    @Test
    void scanQr_walletQr_shouldReturn200WithWalletTransferResult() {
        String qrString = "WALLET_QR:v1:user:target-999";
        Map<String, Object> parsed = Map.of(
                "type", "WALLET_TRANSFER",
                "targetUserId", "target-999");
        when(personalQrUseCase.scanQr(qrString)).thenReturn(parsed);

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                target.scanQr(qrString);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("WALLET_TRANSFER", response.getBody().getData().get("type"));
        assertEquals("target-999", response.getBody().getData().get("targetUserId"));
    }

    @Test
    void scanQr_walletQr_shouldDelegateToUseCaseWithExactQrString() {
        String qrString = "WALLET_QR:v1:user:target-999";
        when(personalQrUseCase.scanQr(qrString)).thenReturn(Map.of("type", "WALLET_TRANSFER"));

        target.scanQr(qrString);

        verify(personalQrUseCase).scanQr(qrString);
    }

    // ─── POST /api/v1/payments/qr/scan — VIETQR ─────────────────────────────

    @Test
    void scanQr_vietQrFormat_shouldReturn200WithVietQrResult() {
        String emvcoQr = "000201010212...6304ABCD";
        Map<String, Object> parsed = Map.of(
                "type", "VIETQR",
                "payload", emvcoQr);
        when(personalQrUseCase.scanQr(emvcoQr)).thenReturn(parsed);

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                target.scanQr(emvcoQr);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("VIETQR", response.getBody().getData().get("type"));
    }

    // ─── POST /api/v1/payments/qr/scan — MERCHANT_PAYMENT ───────────────────

    @Test
    void scanQr_merchantQr_shouldReturn200WithMerchantPaymentResult() {
        String merchantQr = "MERCHANT:order-12345";
        Map<String, Object> parsed = Map.of(
                "type", "MERCHANT_PAYMENT",
                "merchantOrderId", "order-12345");
        when(personalQrUseCase.scanQr(merchantQr)).thenReturn(parsed);

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                target.scanQr(merchantQr);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("MERCHANT_PAYMENT", response.getBody().getData().get("type"));
        assertEquals("order-12345", response.getBody().getData().get("merchantOrderId"));
    }

    // ─── POST /api/v1/payments/qr/scan — UNKNOWN ─────────────────────────────

    @Test
    void scanQr_unknownQr_shouldReturn200WithUnknownType() {
        String junk = "some-garbage-qr";
        when(personalQrUseCase.scanQr(junk))
                .thenReturn(Map.of("type", "UNKNOWN", "raw", junk));

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                target.scanQr(junk);

        assertEquals(200, response.getStatusCode().value());
        assertEquals("UNKNOWN", response.getBody().getData().get("type"));
    }
}
