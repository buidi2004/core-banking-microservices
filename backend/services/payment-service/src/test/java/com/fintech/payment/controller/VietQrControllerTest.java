package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.VietQrService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({VietQrController.class, UserQrController.class})
@AutoConfigureMockMvc(addFilters = false)
class VietQrControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private VietQrService vietQrService;

    @Test
    @DisplayName("POST /api/v1/payments/vietqr/generate: Sinh mã VietQR thành công")
    void generateVietQr_Success() throws Exception {
        VietQrGenerateRequest req = VietQrGenerateRequest.builder()
                .bankBin("970422")
                .accountNumber("0987654321")
                .amount(new BigDecimal("100000"))
                .purpose("Nap tien")
                .build();

        VietQrResponse resp = VietQrResponse.builder()
                .qrRaw("000201010212...")
                .qrDataUrl("data:image/png;base64,iVBORw0KGgo...")
                .bankBin("970422")
                .accountNumber("0987654321")
                .amount(new BigDecimal("100000"))
                .build();

        when(vietQrService.generateVietQr(any(VietQrGenerateRequest.class))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/payments/vietqr/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.qrRaw").value("000201010212..."))
                .andExpect(jsonPath("$.data.bankBin").value("970422"));
    }

    @Test
    @DisplayName("POST /api/v1/payments/vietqr/decode: Giải mã VietQR thành công")
    void decodeVietQr_Success() throws Exception {
        VietQrDecodeRequest req = VietQrDecodeRequest.builder()
                .qrString("00020101021238540010A00000072701240006970422011009876543210208QRIBFTTA53037045802VN63041234")
                .build();

        VietQrDecodeResponse resp = VietQrDecodeResponse.builder()
                .bankBin("970422")
                .bankName("MB Bank")
                .accountNumber("0987654321")
                .amount(new BigDecimal("100000"))
                .purpose("Thanh toan")
                .build();

        when(vietQrService.decodeVietQr(eq(req.getQrString()))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/payments/vietqr/decode")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.bankBin").value("970422"))
                .andExpect(jsonPath("$.data.bankName").value("MB Bank"));
    }

    @Test
    @DisplayName("GET /api/v1/users/me/qrcode: Lấy mã QR cá nhân của người dùng")
    void getMyQrCode_Success() throws Exception {
        VietQrResponse resp = VietQrResponse.builder()
                .qrRaw("0002010102113854...")
                .qrDataUrl("data:image/png;base64,iVBORw0KGgo...")
                .bankBin("970488")
                .accountNumber("user-123-wallet")
                .build();

        when(vietQrService.getUserQrCode(eq("user-123"))).thenReturn(resp);

        mockMvc.perform(get("/api/v1/users/me/qrcode")
                        .header("X-User-Id", "user-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.bankBin").value("970488"));
    }
}
