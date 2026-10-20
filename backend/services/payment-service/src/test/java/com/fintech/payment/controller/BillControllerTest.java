package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.BillService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BillController.class)
@AutoConfigureMockMvc(addFilters = false)
class BillControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BillService billService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/bills/lookup: Tra cứu thông tin hóa đơn")
    void lookupBill_Success() throws Exception {
        BillLookupResponse res = BillLookupResponse.builder()
                .billId("BILL-EVN-001")
                .serviceType("ELECTRICITY")
                .providerCode("EVN_HANOI")
                .providerName("EVN Hà Nội")
                .customerCode("PE01000123456")
                .customerName("NGUYEN VAN A")
                .customerAddress("123 Hoan Kiem, Ha Noi")
                .period("Kỳ 10/2026")
                .amount(new BigDecimal("485000"))
                .dueDate(LocalDate.now().plusDays(7))
                .status("UNPAID")
                .build();

        when(billService.lookupBill("ELECTRICITY", "PE01000123456")).thenReturn(res);

        mockMvc.perform(get("/api/v1/bills/lookup")
                        .param("type", "ELECTRICITY")
                        .param("customerCode", "PE01000123456"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.billId").value("BILL-EVN-001"))
                .andExpect(jsonPath("$.data.amount").value(485000));
    }

    @Test
    @DisplayName("POST /api/v1/bills/pay: Thanh toán hóa đơn")
    void payBill_Success() throws Exception {
        BillPaymentRequest req = BillPaymentRequest.builder()
                .requestId("REQ-001")
                .walletId(UUID.randomUUID().toString())
                .billId("BILL-EVN-001")
                .amount(new BigDecimal("485000"))
                .currency("VND")
                .build();

        BillPaymentResponse res = BillPaymentResponse.builder()
                .transactionId(UUID.randomUUID().toString())
                .billId("BILL-EVN-001")
                .status("SUCCESS")
                .amount(new BigDecimal("485000"))
                .message("Thanh toán hóa đơn thành công")
                .build();

        when(billService.payBill(eq(userId), any(BillPaymentRequest.class))).thenReturn(res);

        mockMvc.perform(post("/api/v1/bills/pay")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }

    @Test
    @DisplayName("POST /api/v1/bills/topup: Nạp tiền điện thoại trả trước")
    void topupPhone_Success() throws Exception {
        PhoneTopupRequest req = PhoneTopupRequest.builder()
                .requestId("REQ-002")
                .walletId(UUID.randomUUID().toString())
                .phoneNumber("0988123456")
                .amount(new BigDecimal("100000"))
                .currency("VND")
                .build();

        PhoneTopupResponse res = PhoneTopupResponse.builder()
                .transactionId(UUID.randomUUID().toString())
                .phoneNumber("0988123456")
                .amount(new BigDecimal("100000"))
                .discountAmount(new BigDecimal("3000"))
                .netAmount(new BigDecimal("97000"))
                .status("SUCCESS")
                .message("Nạp tiền điện thoại thành công")
                .build();

        when(billService.topupPhone(eq(userId), any(PhoneTopupRequest.class))).thenReturn(res);

        mockMvc.perform(post("/api/v1/bills/topup")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.netAmount").value(97000));
    }
}

