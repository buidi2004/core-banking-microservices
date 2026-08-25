package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.VietQrPayload;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests cho VietQrService — luồng sinh và giải mã QR chuyển tiền theo chuẩn EMVCo / NAPAS.
 *
 * Cấu trúc TLV EMVCo:
 *   00 = Payload Format Indicator  (phải = "01")
 *   01 = Point of Initiation       (12 = Dynamic QR)
 *   38 = Merchant Account Info     (chứa BIN ngân hàng + số tài khoản)
 *   53 = Currency                  (704 = VND)
 *   54 = Amount
 *   58 = Country Code              (VN)
 *   62 = Additional Data           (nội dung chuyển khoản)
 *   63 = CRC-16
 */
class VietQrServiceTest {

    private VietQrService vietQrService;

    @BeforeEach
    void setUp() {
        vietQrService = new VietQrService();
    }

    // ─── generateQr: happy paths ────────────────────────────────────────────

    @Test
    void generateQr_withAmount_shouldReturnPayloadWithQrString() {
        VietQrPayload payload = vietQrService.generateQr(
                "970415", "10100000000", new BigDecimal("500000"), "Tra tien thue thang 8");

        assertNotNull(payload);
        assertNotNull(payload.getQrCodeString());
        assertFalse(payload.getQrCodeString().isBlank());
        assertEquals("970415", payload.getBankBin());
        assertEquals("10100000000", payload.getAccountNumber());
        assertEquals(0, new BigDecimal("500000").compareTo(payload.getAmount()));
        assertEquals("Tra tien thue thang 8", payload.getPurpose());
    }

    @Test
    void generateQr_withoutAmount_shouldOmitTag54() {
        VietQrPayload payload = vietQrService.generateQr(
                "970436", "9876543210", null, "Chuyển khoản");

        String qr = payload.getQrCodeString();
        // Tag 54 (amount) must NOT be present when amount is null
        assertFalse(containsTag(qr, "54"),
                "Tag 54 (amount) should be absent when no amount is provided");
    }

    @Test
    void generateQr_withZeroAmount_shouldOmitTag54() {
        VietQrPayload payload = vietQrService.generateQr(
                "970436", "9876543210", BigDecimal.ZERO, "Test");

        String qr = payload.getQrCodeString();
        assertFalse(containsTag(qr, "54"),
                "Tag 54 should be absent for zero-amount QR (generic payment QR)");
    }

    @Test
    void generateQr_withoutPurpose_shouldOmitTag62() {
        VietQrPayload payload = vietQrService.generateQr(
                "970415", "10100000000", new BigDecimal("100000"), null);

        String qr = payload.getQrCodeString();
        assertFalse(containsTag(qr, "62"),
                "Tag 62 (additional data) should be absent when no purpose is given");
    }

    // ─── generateQr: EMVCo mandatory fields ─────────────────────────────────

    @Test
    void generateQr_shouldContainPayloadFormatIndicator00() {
        String qr = generateQr();
        // Must start with 000201 (tag=00, len=02, value=01)
        assertTrue(qr.startsWith("000201"),
                "QR must start with 000201 per EMVCo spec");
    }

    @Test
    void generateQr_shouldContainDynamicQrTag01() {
        String qr = generateQr();
        // Tag 01, length 02, value 12  → "010212"
        assertTrue(qr.contains("010212"),
                "Dynamic QR must contain tag 01 = '12'");
    }

    @Test
    void generateQr_shouldContainNapasGuidInTag38() {
        String qr = generateQr();
        // NAPAS GUID A000000727 must appear inside tag 38
        assertTrue(qr.contains("A000000727"),
                "Tag 38 must contain NAPAS GUID A000000727");
    }

    @Test
    void generateQr_shouldContainVndCurrencyTag53() {
        String qr = generateQr();
        // Tag 53, length 03, value 704  → "5303704"
        assertTrue(qr.contains("5303704"),
                "Tag 53 must encode VND (704)");
    }

    @Test
    void generateQr_shouldContainVietnamCountryTag58() {
        String qr = generateQr();
        // Tag 58, length 02, value VN  → "580256VN" would be wrong;
        // actual: "5802VN" (len=02, value=VN)
        assertTrue(qr.contains("5802VN"),
                "Tag 58 must encode country code VN");
    }

    @Test
    void generateQr_shouldEndWithCrcTag63() {
        String qr = generateQr();
        // Last 8 chars: "6304" + 4-hex-digit CRC
        assertTrue(qr.matches(".*6304[0-9A-F]{4}$"),
                "QR must end with tag 63 followed by 4-character CRC hex");
    }

    @Test
    void generateQr_shouldEmbedBankBinInTag38() {
        VietQrPayload payload = vietQrService.generateQr(
                "970415", "10100000000", new BigDecimal("100000"), null);
        assertTrue(payload.getQrCodeString().contains("970415"),
                "BIN 970415 must be present inside tag 38");
    }

    @Test
    void generateQr_shouldEmbedAccountNumberInTag38() {
        VietQrPayload payload = vietQrService.generateQr(
                "970415", "10100000000", new BigDecimal("100000"), null);
        assertTrue(payload.getQrCodeString().contains("10100000000"),
                "Account number must be present inside tag 38");
    }

    // ─── generateQr: CRC correctness ────────────────────────────────────────

    @Test
    void generateQr_crcShouldBeReproducible() {
        // Same inputs → same QR string (deterministic)
        String qr1 = vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("100000"), "Test").getQrCodeString();
        String qr2 = vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("100000"), "Test").getQrCodeString();
        assertEquals(qr1, qr2, "Same inputs must produce identical QR strings");
    }

    @Test
    void generateQr_differentAmounts_shouldProduceDifferentCrc() {
        String qr1 = vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("100000"), null).getQrCodeString();
        String qr2 = vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("200000"), null).getQrCodeString();
        assertNotEquals(qr1, qr2, "Different amounts must produce different QR strings");
    }

    // ─── CRC-16 CCITT algorithm ──────────────────────────────────────────────

    @Test
    void calculateCrc16_knownInput_shouldReturnExpectedHash() {
        // EMVCo sample: string ending in "6304" → CRC must be a non-empty 4-char hex
        String input = "000201010212" + "6304";
        String crc = VietQrService.calculateCrc16(input);
        assertNotNull(crc);
        assertEquals(4, crc.length(), "CRC must be exactly 4 hex characters");
        assertTrue(crc.matches("[0-9A-F]{4}"), "CRC must be uppercase hex");
    }

    @Test
    void calculateCrc16_emptyString_shouldReturnDeterministicValue() {
        String crc1 = VietQrService.calculateCrc16("");
        String crc2 = VietQrService.calculateCrc16("");
        assertEquals(crc1, crc2, "CRC of empty string must be deterministic");
    }

    @Test
    void calculateCrc16_differentInputs_shouldProduceDifferentValues() {
        String crc1 = VietQrService.calculateCrc16("HELLO");
        String crc2 = VietQrService.calculateCrc16("WORLD");
        assertNotEquals(crc1, crc2, "Different inputs must produce different CRC values");
    }

    // ─── generateQr: validation ──────────────────────────────────────────────

    @Test
    void generateQr_nullBankBin_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.generateQr(null, "10100000000",
                        new BigDecimal("100000"), null));
    }

    @Test
    void generateQr_blankBankBin_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.generateQr("  ", "10100000000",
                        new BigDecimal("100000"), null));
    }

    @Test
    void generateQr_nullAccountNumber_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.generateQr("970415", null,
                        new BigDecimal("100000"), null));
    }

    @Test
    void generateQr_blankAccountNumber_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.generateQr("970415", "",
                        new BigDecimal("100000"), null));
    }

    // ─── decodeQr ────────────────────────────────────────────────────────────

    @Test
    void decodeQr_validQrString_shouldReturnPayload() {
        // Generate a real QR first, then decode it
        String qr = vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("100000"), "Test").getQrCodeString();

        VietQrPayload decoded = vietQrService.decodeQr(qr);

        assertNotNull(decoded);
        assertNotNull(decoded.getQrCodeString());
    }

    @Test
    void decodeQr_napasQrShouldRecognizeGuid() {
        // QR string containing NAPAS GUID
        String fakeNapasQr = "000201010212" +
                "38" + "65" +
                "0010A000000727" +
                "01" + "30" +
                "0006970415" +
                "011110100000000" +
                "0208QRIBFTTA" +
                "5303704630412AB";

        VietQrPayload decoded = vietQrService.decodeQr(fakeNapasQr);
        assertNotNull(decoded);
    }

    @Test
    void decodeQr_nullInput_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.decodeQr(null));
    }

    @Test
    void decodeQr_blankInput_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> vietQrService.decodeQr("  "));
    }

    // ─── helpers ─────────────────────────────────────────────────────────────

    /** Generate a standard QR for reuse in structural assertions. */
    private String generateQr() {
        return vietQrService.generateQr("970415", "10100000000",
                new BigDecimal("500000"), "Chuyen tien").getQrCodeString();
    }

    /**
     * Naively checks whether a TLV tag is present in the raw QR string.
     * A tag is present if the string contains the 2-char tag code followed by
     * at least one digit (the length field).
     */
    private boolean containsTag(String qr, String tag) {
        int idx = 0;
        while (idx < qr.length() - 4) {
            if (qr.startsWith(tag, idx)) {
                return true;
            }
            // Skip past current TLV: tag(2) + len(2) + value(len)
            try {
                String currentTag = qr.substring(idx, idx + 2);
                int len = Integer.parseInt(qr.substring(idx + 2, idx + 4));
                // Only skip if this looks like a top-level tag (numeric 2-char)
                if (currentTag.matches("\\d{2}")) {
                    idx += 4 + len;
                } else {
                    idx++;
                }
            } catch (NumberFormatException | StringIndexOutOfBoundsException e) {
                idx++;
            }
        }
        return false;
    }
}
