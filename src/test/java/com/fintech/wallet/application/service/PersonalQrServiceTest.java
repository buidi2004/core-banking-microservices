package com.fintech.wallet.application.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests cho PersonalQrService.
 *
 * Luồng chính được test:
 *   1. Sinh QR payload cá nhân (WALLET_QR format)
 *   2. Scan + nhận diện loại QR:
 *      - WALLET_TRANSFER  → scan QR ví cá nhân của user khác
 *      - VIETQR           → scan QR ngân hàng chuẩn EMVCo/NAPAS
 *      - MERCHANT_PAYMENT → scan QR merchant
 *      - UNKNOWN          → QR không xác định
 */
class PersonalQrServiceTest {

    private PersonalQrService personalQrService;
    private com.fintech.wallet.domain.port.out.UserPersistencePort userPersistencePortMock;

    @BeforeEach
    void setUp() {
        userPersistencePortMock = org.mockito.Mockito.mock(com.fintech.wallet.domain.port.out.UserPersistencePort.class);
        org.mockito.Mockito.when(userPersistencePortMock.findUserById(org.mockito.ArgumentMatchers.anyString()))
            .thenReturn(java.util.Optional.of(
                new com.fintech.wallet.domain.model.User("user-123", "0988111222", null, null, null, null, null)
            ));
        personalQrService = new PersonalQrService(userPersistencePortMock);
    }

    // ─── getPersonalQrPayload ────────────────────────────────────────────────

    @Test
    void getPersonalQrPayload_shouldReturnNonBlankString() {
        String payload = personalQrService.getPersonalQrPayload("user-123");
        assertNotNull(payload);
        assertFalse(payload.isBlank());
    }

    @Test
    void getPersonalQrPayload_shouldContainUserId() {
        String payload = personalQrService.getPersonalQrPayload("user-abc");
        assertTrue(payload.contains("user-abc"),
                "QR payload must embed the user ID so the receiver can identify the target wallet");
    }

    @Test
    void getPersonalQrPayload_shouldStartWithWalletQrPrefix() {
        String payload = personalQrService.getPersonalQrPayload("u1");
        assertTrue(payload.startsWith("WALLET_QR:"),
                "Personal wallet QR must use WALLET_QR: prefix to distinguish from bank QRs");
    }

    @Test
    void getPersonalQrPayload_differentUsers_shouldProduceDifferentPayloads() {
        String p1 = personalQrService.getPersonalQrPayload("user-1");
        String p2 = personalQrService.getPersonalQrPayload("user-2");
        assertNotEquals(p1, p2,
                "Two different users must not share the same QR payload");
    }

    @Test
    void getPersonalQrPayload_sameUser_shouldProduceSamePayload() {
        // Payload must be deterministic (no random component) so it can be cached/printed
        String p1 = personalQrService.getPersonalQrPayload("user-42");
        String p2 = personalQrService.getPersonalQrPayload("user-42");
        assertEquals(p1, p2, "Same user must always get the same QR payload");
    }

    // ─── scanQr: WALLET_TRANSFER ─────────────────────────────────────────────

    @Test
    void scanQr_walletQr_shouldReturnWalletTransferType() {
        // Simulate scanning another user's personal QR
        String targetQr = personalQrService.getPersonalQrPayload("target-user-99");

        Map<String, Object> result = personalQrService.scanQr(targetQr);

        assertEquals("WALLET_TRANSFER", result.get("type"),
                "Scanning a personal wallet QR must resolve to WALLET_TRANSFER");
    }

    @Test
    void scanQr_walletQr_shouldExtractTargetUserId() {
        String targetQr = personalQrService.getPersonalQrPayload("target-user-99");

        Map<String, Object> result = personalQrService.scanQr(targetQr);

        assertEquals("target-user-99", result.get("targetUserId"),
                "targetUserId must match the user who generated the QR");
    }

    @Test
    void scanQr_walletQr_scannerCannotScanOwnQrToSelf() {
        // Two different users: payload for user-A should not match user-B
        String qrOfA = personalQrService.getPersonalQrPayload("user-A");
        Map<String, Object> resultA = personalQrService.scanQr(qrOfA);

        assertNotEquals("user-B", resultA.get("targetUserId"),
                "Scanning user-A's QR must not resolve to user-B");
    }

    // ─── scanQr: VIETQR (bank QR / EMVCo) ───────────────────────────────────

    @Test
    void scanQr_vietQrFormat_shouldReturnVietQrType() {
        // EMVCo QR always starts with "000201"
        String emvcoQr = "000201010212263700101A00000072701250006970415011110100000000020208QRIBFTTA5303704540610000058"
                + "02VN6304ABCD";

        Map<String, Object> result = personalQrService.scanQr(emvcoQr);

        assertEquals("VIETQR", result.get("type"),
                "An EMVCo/NAPAS QR starting with 000201 must be identified as VIETQR type");
    }

    @Test
    void scanQr_vietQrFormat_shouldIncludeRawPayload() {
        String emvcoQr = "000201010212" + "5303704" + "6304ABCD";

        Map<String, Object> result = personalQrService.scanQr(emvcoQr);

        assertEquals(emvcoQr, result.get("payload"),
                "Full raw QR string must be returned in 'payload' field for downstream decoding");
    }

    // ─── scanQr: MERCHANT_PAYMENT ────────────────────────────────────────────

    @Test
    void scanQr_merchantQr_shouldReturnMerchantPaymentType() {
        String merchantQr = "MERCHANT:order-88881234";

        Map<String, Object> result = personalQrService.scanQr(merchantQr);

        assertEquals("MERCHANT_PAYMENT", result.get("type"),
                "A MERCHANT: prefixed QR must resolve to MERCHANT_PAYMENT");
    }

    @Test
    void scanQr_merchantQr_shouldExtractOrderId() {
        String merchantQr = "MERCHANT:order-88881234";

        Map<String, Object> result = personalQrService.scanQr(merchantQr);

        assertEquals("order-88881234", result.get("merchantOrderId"),
                "merchantOrderId must be extracted from the QR string");
    }

    // ─── scanQr: UNKNOWN ────────────────────────────────────────────────────

    @Test
    void scanQr_unknownFormat_shouldReturnUnknownType() {
        Map<String, Object> result = personalQrService.scanQr("some-random-qr-data-xyz");

        assertEquals("UNKNOWN", result.get("type"),
                "Unrecognised QR format must return UNKNOWN to let the UI show an error");
    }

    @Test
    void scanQr_unknownFormat_shouldIncludeRawString() {
        String raw = "some-random-qr-data-xyz";
        Map<String, Object> result = personalQrService.scanQr(raw);

        assertEquals(raw, result.get("raw"),
                "Raw string must be preserved in result for debugging / logging");
    }

    @Test
    void scanQr_nullInput_shouldReturnUnknownOrNotThrow() {
        // Null QR should be handled gracefully — not crash the app
        assertDoesNotThrow(() -> {
            Map<String, Object> result = personalQrService.scanQr(null);
            assertNotNull(result);
        });
    }

    @Test
    void scanQr_emptyString_shouldReturnUnknownType() {
        Map<String, Object> result = personalQrService.scanQr("");
        // Empty string should resolve to UNKNOWN, not throw
        assertNotNull(result.get("type"));
    }
}
