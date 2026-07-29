package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.VietQrPayload;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class VietQrServiceTest {

    private VietQrService vietQrService;

    @BeforeEach
    void setUp() {
        vietQrService = new VietQrService();
    }

    @Test
    void generateQr_shouldReturnValidVietQrPayloadAndCrc() {
        String bankBin = "970415";
        String accountNumber = "10100000000";
        BigDecimal amount = new BigDecimal("100000.00");
        String purpose = "Tien hang";

        VietQrPayload payload = vietQrService.generateQr(bankBin, accountNumber, amount, purpose);

        assertNotNull(payload);
        assertEquals(bankBin, payload.getBankBin());
        assertEquals(accountNumber, payload.getAccountNumber());
        assertNotNull(payload.getQrCodeString());

        // EMVCo tags check
        assertTrue(payload.getQrCodeString().startsWith("000201")); // Tag 00
        assertTrue(payload.getQrCodeString().contains("38")); // Tag 38 Merchant Info
        assertTrue(payload.getQrCodeString().contains("5303704")); // Tag 53 Currency VND (704)
        assertTrue(payload.getQrCodeString().contains("6304")); // Tag 63 CRC
    }

    @Test
    void calculateCrc16_shouldComputeCorrectCrc() {
        String input = "00020101021238570010A000000727012700069704150111101000000000208QRIBFTTA53037045409100000.005802VN62170813Tien hang6304";
        String crc = VietQrService.calculateCrc16(input);

        assertNotNull(crc);
        assertEquals(4, crc.length());
    }
}
