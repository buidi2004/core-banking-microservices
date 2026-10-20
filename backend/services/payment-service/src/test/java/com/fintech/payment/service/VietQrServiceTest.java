package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bank;
import com.fintech.payment.dto.*;
import com.fintech.payment.repository.BankRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VietQrServiceTest {

    @Mock
    private BankRepository bankRepository;

    private VietQrService vietQrService;

    @BeforeEach
    void setUp() {
        vietQrService = new VietQrService(bankRepository);
    }

    @Test
    @DisplayName("generateVietQr: Sinh chuỗi EMVCo hợp lệ có Tag 00..63 và mã QR Base64 PNG")
    void generateVietQr_Success() {
        VietQrGenerateRequest request = VietQrGenerateRequest.builder()
                .bankBin("970422") // MB Bank
                .accountNumber("0987654321")
                .amount(new BigDecimal("250000"))
                .purpose("Chuyen tien an trua")
                .build();

        VietQrResponse response = vietQrService.generateVietQr(request);

        assertThat(response).isNotNull();
        assertThat(response.getQrRaw()).startsWith("000201");
        assertThat(response.getQrRaw()).contains("A000000727"); // NAPAS GUID
        assertThat(response.getQrRaw()).contains("970422");     // Bank BIN
        assertThat(response.getQrRaw()).contains("0987654321"); // Account number
        assertThat(response.getQrRaw()).contains("6304");       // CRC tag
        assertThat(response.getQrDataUrl()).startsWith("data:image/png;base64,");
        assertThat(response.getBankBin()).isEqualTo("970422");
        assertThat(response.getAccountNumber()).isEqualTo("0987654321");
        assertThat(response.getAmount()).isEqualByComparingTo("250000");
    }

    @Test
    @DisplayName("decodeVietQr: Giải mã chính xác chuỗi VietQR chuẩn EMVCo và tính toán CRC16 chuẩn")
    void decodeVietQr_Success() {
        // Sinh 1 mã VietQR hợp lệ trước
        VietQrGenerateRequest genReq = VietQrGenerateRequest.builder()
                .bankBin("970436") // Vietcombank
                .accountNumber("1234567890")
                .amount(new BigDecimal("500000"))
                .purpose("Thanh toan tien nha")
                .build();

        when(bankRepository.findByBin("970436")).thenReturn(Optional.of(
                Bank.builder().bin("970436").shortName("Vietcombank").name("Ngân hàng Ngoại Thương Việt Nam").build()
        ));

        VietQrResponse genResp = vietQrService.generateVietQr(genReq);

        // Decode lại mã vừa sinh
        VietQrDecodeResponse decodeResp = vietQrService.decodeVietQr(genResp.getQrRaw());

        assertThat(decodeResp).isNotNull();
        assertThat(decodeResp.getBankBin()).isEqualTo("970436");
        assertThat(decodeResp.getBankName()).isEqualTo("Vietcombank");
        assertThat(decodeResp.getAccountNumber()).isEqualTo("1234567890");
        assertThat(decodeResp.getAmount()).isEqualByComparingTo("500000");
        assertThat(decodeResp.getPurpose()).isEqualTo("Thanh toan tien nha");
    }

    @Test
    @DisplayName("decodeVietQr: Chuỗi QR bị sửa đổi hoặc sai CRC16 bị từ chối")
    void decodeVietQr_CorruptedCrcFails() {
        String invalidQr = "00020101021238540010A00000072701240006970422011009876543210208QRIBFTTA53037045802VN6304FFFF";

        assertThatThrownBy(() -> vietQrService.decodeVietQr(invalidQr))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã VietQR không hợp lệ hoặc sai checksum");
    }
}

