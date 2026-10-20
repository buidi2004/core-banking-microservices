package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.SavingsService;
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
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(SavingsController.class)
@AutoConfigureMockMvc(addFilters = false)
class SavingsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private SavingsService savingsService;

    @Test
    @DisplayName("GET /api/v1/savings/products: Lấy danh sách sản phẩm tiết kiệm thành công")
    void getProducts_Success() throws Exception {
        SavingsProductDto product = SavingsProductDto.builder()
                .productType("TIET_KIEM_PHAT_LOC")
                .productName("Tiết Kiệm Phát Lộc")
                .description("Nhận lãi cuối kỳ cao nhất")
                .minDeposit(new BigDecimal("1000000"))
                .baseRate(new BigDecimal("7.2"))
                .terms(List.of(
                        SavingsProductDto.TermRateDto.builder().months(6).rate(new BigDecimal("5.8")).build(),
                        SavingsProductDto.TermRateDto.builder().months(12).rate(new BigDecimal("7.2")).build()
                ))
                .build();

        when(savingsService.getProducts()).thenReturn(List.of(product));

        mockMvc.perform(get("/api/v1/savings/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].productType").value("TIET_KIEM_PHAT_LOC"))
                .andExpect(jsonPath("$.data[0].minDeposit").value(1000000));
    }

    @Test
    @DisplayName("POST /api/v1/savings/accounts: Mở sổ tiết kiệm thành công")
    void openSavings_Success() throws Exception {
        OpenSavingsRequest req = OpenSavingsRequest.builder()
                .walletId("wallet-123")
                .productType("TIET_KIEM_PHAT_LOC")
                .termMonths(12)
                .depositAmount(new BigDecimal("5000000"))
                .pinToken("valid-pin")
                .build();

        SavingsAccountResponse resp = SavingsAccountResponse.builder()
                .id(UUID.randomUUID().toString())
                .accountNumber("TKPL-20261021-999")
                .userId("user-123")
                .productName("Tiết Kiệm Phát Lộc")
                .principal(new BigDecimal("5000000"))
                .interestRate(new BigDecimal("7.2"))
                .termMonths(12)
                .expectedInterest(new BigDecimal("360000"))
                .status("ACTIVE")
                .startDate(LocalDate.now())
                .maturityDate(LocalDate.now().plusMonths(12))
                .build();

        when(savingsService.openSavings(eq("user-123"), any(OpenSavingsRequest.class))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/savings/accounts")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accountNumber").value("TKPL-20261021-999"))
                .andExpect(jsonPath("$.data.principal").value(5000000))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"));
    }

    @Test
    @DisplayName("GET /api/v1/savings/accounts: Liệt kê sổ tiết kiệm của người dùng")
    void listSavings_Success() throws Exception {
        SavingsAccountResponse resp = SavingsAccountResponse.builder()
                .id(UUID.randomUUID().toString())
                .accountNumber("TKPL-123")
                .userId("user-123")
                .principal(new BigDecimal("10000000"))
                .status("ACTIVE")
                .build();

        when(savingsService.getUserSavings("user-123")).thenReturn(List.of(resp));

        mockMvc.perform(get("/api/v1/savings/accounts")
                        .header("X-User-Id", "user-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].accountNumber").value("TKPL-123"));
    }

    @Test
    @DisplayName("POST /api/v1/savings/accounts/{id}/settle: Tất toán sổ tiết kiệm")
    void settleSavings_Success() throws Exception {
        SettleSavingsRequest req = SettleSavingsRequest.builder()
                .pinToken("valid-pin")
                .build();

        SettleSavingsResponse resp = SettleSavingsResponse.builder()
                .accountNumber("TKPL-123")
                .earlySettlement(false)
                .principalReturned(new BigDecimal("10000000"))
                .interestEarned(new BigDecimal("720000"))
                .totalPayout(new BigDecimal("10720000"))
                .creditedToWallet("wallet-123")
                .build();

        when(savingsService.settleSavings(eq("acc-123"), eq("user-123"), any())).thenReturn(resp);

        mockMvc.perform(post("/api/v1/savings/accounts/acc-123/settle")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalPayout").value(10720000));
    }
}

