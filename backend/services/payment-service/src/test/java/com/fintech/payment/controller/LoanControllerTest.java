package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.LoanService;
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

@WebMvcTest(LoanController.class)
@AutoConfigureMockMvc(addFilters = false)
class LoanControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private LoanService loanService;

    @Test
    @DisplayName("GET /api/v1/loans/products: Lấy danh sách sản phẩm vay")
    void getProducts_Success() throws Exception {
        LoanProductDto prod = LoanProductDto.builder()
                .productType("VAY_TIEU_DUNG_NHANH")
                .productName("Vay Tiêu Dùng Sen Hồng")
                .minAmount(new BigDecimal("5000000"))
                .maxAmount(new BigDecimal("50000000"))
                .annualRate(new BigDecimal("14.4"))
                .availableTerms(List.of(3, 6, 12, 24))
                .build();

        when(loanService.getProducts()).thenReturn(List.of(prod));

        mockMvc.perform(get("/api/v1/loans/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].productType").value("VAY_TIEU_DUNG_NHANH"));
    }

    @Test
    @DisplayName("POST /api/v1/loans/apply: Nộp hồ sơ và giải ngân vay thành công")
    void applyLoan_Success() throws Exception {
        LoanApplicationRequest req = LoanApplicationRequest.builder()
                .walletId("wallet-123")
                .productType("VAY_TIEU_DUNG_NHANH")
                .amount(new BigDecimal("15000000"))
                .termMonths(6)
                .purpose("Mua sắm")
                .pinToken("pin-token-123")
                .build();

        LoanApplicationResponse resp = LoanApplicationResponse.builder()
                .id(UUID.randomUUID().toString())
                .contractNumber("LN-20261021-001")
                .userId("user-123")
                .productName("Vay Tiêu Dùng Sen Hồng")
                .principalAmount(new BigDecimal("15000000"))
                .termMonths(6)
                .annualInterestRate(new BigDecimal("14.4"))
                .monthlyPayment(new BigDecimal("2680000"))
                .status("DISBURSED")
                .disbursedAt(LocalDate.now().toString())
                .firstDueDate(LocalDate.now().plusMonths(1).toString())
                .build();

        when(loanService.applyLoan(eq("user-123"), any(LoanApplicationRequest.class))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/loans/apply")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.contractNumber").value("LN-20261021-001"))
                .andExpect(jsonPath("$.data.principalAmount").value(15000000))
                .andExpect(jsonPath("$.data.status").value("DISBURSED"));
    }

    @Test
    @DisplayName("GET /api/v1/loans/{id}/schedule: Lấy lịch trả nợ của khoản vay")
    void getLoanSchedule_Success() throws Exception {
        LoanScheduleResponse resp = LoanScheduleResponse.builder()
                .contractNumber("LN-001")
                .principalAmount(new BigDecimal("15000000"))
                .termMonths(6)
                .schedule(List.of(
                        LoanScheduleResponse.ScheduleItemDto.builder()
                                .termNumber(1)
                                .dueDate(LocalDate.now().plusMonths(1).toString())
                                .principalAmount(new BigDecimal("2500000"))
                                .interestAmount(new BigDecimal("180000"))
                                .totalAmount(new BigDecimal("2680000"))
                                .remainingBalance(new BigDecimal("12500000"))
                                .status("DUE")
                                .build()
                ))
                .build();

        when(loanService.getLoanSchedule(eq("loan-123"), eq("user-123"))).thenReturn(resp);

        mockMvc.perform(get("/api/v1/loans/loan-123/schedule")
                        .header("X-User-Id", "user-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.contractNumber").value("LN-001"))
                .andExpect(jsonPath("$.data.schedule[0].termNumber").value(1));
    }

    @Test
    @DisplayName("POST /api/v1/loans/{id}/repay: Trích nợ trả kỳ hạn thành công")
    void repayTerm_Success() throws Exception {
        LoanRepaymentRequest req = LoanRepaymentRequest.builder()
                .termNumber(1)
                .amount(new BigDecimal("2680000"))
                .pinToken("pin-token-123")
                .build();

        LoanRepaymentResponse resp = LoanRepaymentResponse.builder()
                .contractNumber("LN-001")
                .termNumber(1)
                .paidAmount(new BigDecimal("2680000"))
                .remainingPrincipal(new BigDecimal("12500000"))
                .status("PAID")
                .isFullyRepaid(false)
                .build();

        when(loanService.repayTerm(eq("loan-123"), eq("user-123"), any())).thenReturn(resp);

        mockMvc.perform(post("/api/v1/loans/loan-123/repay")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.paidAmount").value(2680000))
                .andExpect(jsonPath("$.data.status").value("PAID"));
    }
}

