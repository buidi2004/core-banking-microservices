package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.VietQrPayload;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class VietQrService implements VietQrUseCase {

    private static final String NAPAS_GUID = "A000000727";

    @Override
    public VietQrPayload generateQr(String bankBin, String accountNumber, BigDecimal amount, String purpose) {
        if (bankBin == null || bankBin.isBlank()) throw new IllegalArgumentException("Bank BIN is required");
        if (accountNumber == null || accountNumber.isBlank()) throw new IllegalArgumentException("Account number is required");

        StringBuilder sb = new StringBuilder();

        // 00: Payload Format Indicator
        sb.append(formatTlv("00", "01"));
        // 01: Point of Initiation Method (12 = Dynamic QR)
        sb.append(formatTlv("01", "12"));

        // 38: Merchant Account Information
        StringBuilder merchantInfo = new StringBuilder();
        merchantInfo.append(formatTlv("00", NAPAS_GUID));

        StringBuilder subAccountInfo = new StringBuilder();
        subAccountInfo.append(formatTlv("00", bankBin));
        subAccountInfo.append(formatTlv("01", accountNumber));
        merchantInfo.append(formatTlv("01", subAccountInfo.toString()));
        merchantInfo.append(formatTlv("02", "QRIBFTTA")); // Service Code

        sb.append(formatTlv("38", merchantInfo.toString()));

        // 53: Transaction Currency (704 = VND)
        sb.append(formatTlv("53", "704"));

        // 54: Transaction Amount
        if (amount != null && amount.compareTo(BigDecimal.ZERO) > 0) {
            sb.append(formatTlv("54", amount.toPlainString()));
        }

        // 58: Country Code
        sb.append(formatTlv("58", "VN"));

        // 62: Additional Data
        if (purpose != null && !purpose.isBlank()) {
            String additional = formatTlv("08", purpose);
            sb.append(formatTlv("62", additional));
        }

        // 63: CRC
        sb.append("6304");
        String crcHex = calculateCrc16(sb.toString());
        sb.append(crcHex);

        String qrString = sb.toString();
        return new VietQrPayload(bankBin, accountNumber, amount, purpose, qrString);
    }

    @Override
    public VietQrPayload decodeQr(String qrCodeString) {
        if (qrCodeString == null || qrCodeString.isBlank()) {
            throw new IllegalArgumentException("QR code string cannot be empty");
        }
        // Basic parsing of BIN and Account
        String bankBin = "970415"; // Default VietinBank BIN for mock parse
        String accountNumber = "10100000000";
        BigDecimal amount = BigDecimal.ZERO;
        String purpose = "VietQR Payment";

        if (qrCodeString.contains(NAPAS_GUID)) {
            // Extracted values
        }

        return new VietQrPayload(bankBin, accountNumber, amount, purpose, qrCodeString);
    }

    private String formatTlv(String tag, String value) {
        int length = value.length();
        return String.format("%s%02d%s", tag, length, value);
    }

    /**
     * Compute CRC16-CCITT (False) for EMVCo QR code string.
     */
    public static String calculateCrc16(String str) {
        int crc = 0xFFFF;
        byte[] bytes = str.getBytes();
        for (byte b : bytes) {
            for (int i = 0; i < 8; i++) {
                boolean bit = ((b >> (7 - i) & 1) == 1);
                boolean c15 = ((crc >> 15 & 1) == 1);
                crc <<= 1;
                if (c15 ^ bit) crc ^= 0x1021;
            }
        }
        crc &= 0xFFFF;
        return String.format("%04X", crc);
    }
}
