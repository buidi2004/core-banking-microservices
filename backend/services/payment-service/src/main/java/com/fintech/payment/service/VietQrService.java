package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bank;
import com.fintech.payment.dto.*;
import com.fintech.payment.repository.BankRepository;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VietQrService {

    private final BankRepository bankRepository;

    public VietQrResponse generateVietQr(VietQrGenerateRequest request) {
        String rawQr = buildEmvCoString(request);
        String dataUrl = renderQrImageBase64(rawQr, 320, 320);

        return VietQrResponse.builder()
                .qrRaw(rawQr)
                .qrDataUrl(dataUrl)
                .bankBin(request.getBankBin())
                .accountNumber(request.getAccountNumber())
                .amount(request.getAmount())
                .purpose(request.getPurpose())
                .build();
    }

    public VietQrDecodeResponse decodeVietQr(String qrString) {
        if (qrString == null || qrString.length() < 16) {
            throw new IllegalArgumentException("Chuỗi VietQR không đúng định dạng chuẩn.");
        }

        // Verify CRC16 Checksum
        int crcIndex = qrString.indexOf("6304");
        if (crcIndex < 0 || crcIndex + 8 != qrString.length()) {
            throw new IllegalArgumentException("Mã VietQR không hợp lệ hoặc thiếu trường mã kiểm tra CRC (Tag 63).");
        }

        String dataForCrc = qrString.substring(0, crcIndex + 4);
        String expectedCrc = qrString.substring(crcIndex + 4).toUpperCase();
        String actualCrc = calculateCrc16(dataForCrc).toUpperCase();

        if (!expectedCrc.equals(actualCrc)) {
            log.warn("VietQR CRC16 Mismatch: expected={}, actual={}", expectedCrc, actualCrc);
            throw new IllegalArgumentException("Mã VietQR không hợp lệ hoặc sai checksum.");
        }

        // Parse TLV Elements
        Map<String, String> tags = parseTlv(qrString.substring(0, crcIndex));

        String merchantInfo = tags.get("38");
        if (merchantInfo == null) {
            throw new IllegalArgumentException("Không tìm thấy thông tin tài khoản thụ hưởng trong mã QR.");
        }

        Map<String, String> subTags = parseTlv(merchantInfo);
        String consumerAccountInfo = subTags.get("01");
        String bankBin = "";
        String accountNumber = "";

        if (consumerAccountInfo != null) {
            Map<String, String> accountTags = parseTlv(consumerAccountInfo);
            bankBin = accountTags.getOrDefault("00", "");
            accountNumber = accountTags.getOrDefault("01", "");
        }

        String amountStr = tags.get("54");
        BigDecimal amount = (amountStr != null && !amountStr.isBlank()) ? new BigDecimal(amountStr) : null;

        String purpose = "";
        String additionalData = tags.get("62");
        if (additionalData != null) {
            Map<String, String> addTags = parseTlv(additionalData);
            purpose = addTags.getOrDefault("08", "");
        }

        String bankName = bankRepository.findByBin(bankBin)
                .map(Bank::getShortName)
                .orElse(getFallbackBankName(bankBin));

        return VietQrDecodeResponse.builder()
                .bankBin(bankBin)
                .bankName(bankName)
                .accountNumber(accountNumber)
                .amount(amount)
                .purpose(purpose)
                .serviceCode(subTags.getOrDefault("02", "QRIBFTTA"))
                .build();
    }

    public VietQrResponse getUserQrCode(String userId) {
        String bankBin = "970488"; // SenBank National Acquirer BIN
        return generateVietQr(VietQrGenerateRequest.builder()
                .bankBin(bankBin)
                .accountNumber(userId)
                .purpose("Chuyen tien SenBank")
                .build());
    }

    private String buildEmvCoString(VietQrGenerateRequest request) {
        StringBuilder sb = new StringBuilder();

        // Tag 00: Payload Format Indicator (01)
        appendTlv(sb, "00", "01");

        // Tag 01: Point of Initiation (11=Static, 12=Dynamic with amount)
        appendTlv(sb, "01", request.getAmount() != null ? "12" : "11");

        // Tag 38: Merchant Account Information
        StringBuilder merchant = new StringBuilder();
        appendTlv(merchant, "00", "A000000727"); // NAPAS AID/GUID

        StringBuilder beneficiary = new StringBuilder();
        appendTlv(beneficiary, "00", request.getBankBin());
        appendTlv(beneficiary, "01", request.getAccountNumber());

        appendTlv(merchant, "01", beneficiary.toString());
        appendTlv(merchant, "02", "QRIBFTTA"); // Fast transfer service code

        appendTlv(sb, "38", merchant.toString());

        // Tag 53: Transaction Currency (704 = VND)
        appendTlv(sb, "53", "704");

        // Tag 54: Amount (if provided)
        if (request.getAmount() != null && request.getAmount().compareTo(BigDecimal.ZERO) > 0) {
            appendTlv(sb, "54", request.getAmount().toBigInteger().toString());
        }

        // Tag 58: Country Code (VN)
        appendTlv(sb, "58", "VN");

        // Tag 62: Additional Data Field (Purpose)
        if (request.getPurpose() != null && !request.getPurpose().isBlank()) {
            StringBuilder addData = new StringBuilder();
            appendTlv(addData, "08", request.getPurpose());
            appendTlv(sb, "62", addData.toString());
        }

        // Tag 63: CRC16 Checksum
        sb.append("6304");
        String crc = calculateCrc16(sb.toString());
        sb.append(crc);

        return sb.toString();
    }

    private void appendTlv(StringBuilder sb, String tag, String value) {
        if (value == null) return;
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        sb.append(tag);
        sb.append(String.format("%02d", bytes.length));
        sb.append(value);
    }

    private Map<String, String> parseTlv(String tlvData) {
        Map<String, String> result = new HashMap<>();
        int i = 0;
        int len = tlvData.length();

        while (i + 4 <= len) {
            String tag = tlvData.substring(i, i + 2);
            int length;
            try {
                length = Integer.parseInt(tlvData.substring(i + 2, i + 4));
            } catch (NumberFormatException e) {
                break;
            }

            if (i + 4 + length > len) {
                break;
            }

            String value = tlvData.substring(i + 4, i + 4 + length);
            result.put(tag, value);
            i += 4 + length;
        }

        return result;
    }

    public static String calculateCrc16(String input) {
        int crc = 0xFFFF;
        int polynomial = 0x1021;
        byte[] bytes = input.getBytes(StandardCharsets.US_ASCII);

        for (byte b : bytes) {
            for (int i = 0; i < 8; i++) {
                boolean bit = ((b >> (7 - i)) & 1) == 1;
                boolean c15 = ((crc >> 15) & 1) == 1;
                crc <<= 1;
                if (c15 ^ bit) {
                    crc ^= polynomial;
                }
            }
        }

        crc &= 0xFFFF;
        return String.format("%04X", crc);
    }

    private String renderQrImageBase64(String text, int width, int height) {
        try {
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            Map<EncodeHintType, Object> hints = new HashMap<>();
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
            hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
            hints.put(EncodeHintType.MARGIN, 1);

            BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, width, height, hints);
            ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
            byte[] pngData = pngOutputStream.toByteArray();
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(pngData);
        } catch (Exception e) {
            log.error("Lỗi khi render ảnh QR code: {}", e.getMessage());
            return "";
        }
    }

    private String getFallbackBankName(String bin) {
        return switch (bin) {
            case "970436" -> "Vietcombank";
            case "970422" -> "MB Bank";
            case "970407" -> "Techcombank";
            case "970415" -> "VietinBank";
            case "970418" -> "BIDV";
            case "970423" -> "TPBank";
            case "970488" -> "SenBank";
            default -> "Ngân hàng liên kết (" + bin + ")";
        };
    }
}

