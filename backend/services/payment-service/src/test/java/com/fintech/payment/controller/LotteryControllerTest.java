package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.LotteryService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(LotteryController.class)
@AutoConfigureMockMvc(addFilters = false)
class LotteryControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private LotteryService lotteryService;

    @Test
    @DisplayName("GET /api/v1/lottery/results trả về danh sách kết quả")
    void getResults_Success() throws Exception {
        when(lotteryService.getLatestResults()).thenReturn(List.of(
                LotteryResultDto.builder()
                        .game("Mega 6/45")
                        .period("Kỳ #01289 • 04/09/2026")
                        .jackpot1("24.180.000.000 đ")
                        .numbers(List.of(5, 12, 18, 29, 36, 44))
                        .build()
        ));

        mockMvc.perform(get("/api/v1/lottery/results"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].game").value("Mega 6/45"))
                .andExpect(jsonPath("$.data[0].jackpot1").value("24.180.000.000 đ"));
    }

    @Test
    @DisplayName("GET /api/v1/lottery/my-tickets trả về vé của user")
    void getMyTickets_Success() throws Exception {
        when(lotteryService.getUserTickets(eq("user-123"))).thenReturn(List.of(
                LotteryTicketDto.builder()
                        .code("VTL-8829104")
                        .game("Power 6/55")
                        .status("CHỜ MỞ THƯỞNG")
                        .build()
        ));

        mockMvc.perform(get("/api/v1/lottery/my-tickets")
                        .header("X-User-Id", "user-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].code").value("VTL-8829104"));
    }

    @Test
    @DisplayName("POST /api/v1/lottery/buy thành công")
    void buyTicket_Success() throws Exception {
        LotteryBuyRequest req = LotteryBuyRequest.builder()
                .gameName("Mega 6/45")
                .numbers(List.of(3, 12, 18, 27, 35, 42))
                .quantity(1)
                .build();

        when(lotteryService.buyTicket(eq("user-123"), any(LotteryBuyRequest.class))).thenReturn(
                LotteryBuyResponse.builder()
                        .ticketCode("VTL-1234567")
                        .gameName("Mega 6/45")
                        .amount(10000L)
                        .quantity(1)
                        .status("CHỜ MỞ THƯỞNG")
                        .build()
        );

        mockMvc.perform(post("/api/v1/lottery/buy")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.ticketCode").value("VTL-1234567"));
    }
}

