package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.*;
import com.fintech.payment.service.CardService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(CardController.class)
@AutoConfigureMockMvc(addFilters = false)
class CardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CardService cardService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/cards: Lấy danh sách thẻ của người dùng")
    void getCards_Success() throws Exception {
        CardDto card = CardDto.builder()
                .id(UUID.randomUUID().toString())
                .type("credit")
                .title("SEN HỒNG VISA SIGNATURE")
                .tier("THẺ TÍN DỤNG QUỐC TẾ")
                .number("4288990012345678")
                .maskedNumber("•••• •••• •••• 5678")
                .holder("NGUYEN VAN A")
                .expiry("12/29")
                .cvv("889")
                .limit(new BigDecimal("150000000"))
                .available(new BigDecimal("120000000"))
                .colorScheme("platinum")
                .status("ACTIVE")
                .onlinePayment(true)
                .intlPayment(true)
                .atmWithdraw(true)
                .contactless(true)
                .build();

        when(cardService.getUserCards(eq(userId), any())).thenReturn(List.of(card));

        mockMvc.perform(get("/api/v1/cards")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].type").value("credit"))
                .andExpect(jsonPath("$.data[0].title").value("SEN HỒNG VISA SIGNATURE"))
                .andExpect(jsonPath("$.data[0].limit").value(150000000));
    }

    @Test
    @DisplayName("POST /api/v1/cards/issue: Phát hành thẻ mới")
    void issueCard_Success() throws Exception {
        CardIssueRequest req = CardIssueRequest.builder()
                .type("DEBIT")
                .physical(false)
                .build();

        CardDto card = CardDto.builder()
                .id(UUID.randomUUID().toString())
                .type("debit")
                .title("SEN HỒNG NAPAS CHIP")
                .tier("THẺ GHI NỢ NỘI ĐỊA")
                .number("9704220088990011")
                .maskedNumber("•••• •••• •••• 0011")
                .holder("NGUYEN VAN A")
                .status("ACTIVE")
                .build();

        when(cardService.issueCard(eq(userId), any(), any(CardIssueRequest.class))).thenReturn(card);

        mockMvc.perform(post("/api/v1/cards/issue")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.type").value("debit"));
    }

    @Test
    @DisplayName("PATCH /api/v1/cards/{id}/status: Cập nhật trạng thái thẻ")
    void updateCardStatus_Success() throws Exception {
        String cardId = UUID.randomUUID().toString();
        CardStatusRequest req = CardStatusRequest.builder().status("LOCKED").build();

        CardDto card = CardDto.builder()
                .id(cardId)
                .status("LOCKED")
                .build();

        when(cardService.updateCardStatus(eq(userId), eq(cardId), any())).thenReturn(card);

        mockMvc.perform(patch("/api/v1/cards/" + cardId + "/status")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("LOCKED"));
    }

    @Test
    @DisplayName("PUT /api/v1/cards/{id}/settings: Cập nhật tính năng thẻ")
    void updateCardSettings_Success() throws Exception {
        String cardId = UUID.randomUUID().toString();
        CardSettingsRequest req = CardSettingsRequest.builder()
                .onlinePayment(false)
                .intlPayment(false)
                .contactless(true)
                .atmWithdraw(false)
                .build();

        CardDto card = CardDto.builder()
                .id(cardId)
                .onlinePayment(false)
                .intlPayment(false)
                .contactless(true)
                .atmWithdraw(false)
                .build();

        when(cardService.updateCardSettings(eq(userId), eq(cardId), any())).thenReturn(card);

        mockMvc.perform(put("/api/v1/cards/" + cardId + "/settings")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.onlinePayment").value(false));
    }
}

