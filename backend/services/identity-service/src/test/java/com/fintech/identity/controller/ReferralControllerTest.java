package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ReferralController.class)
@AutoConfigureMockMvc(addFilters = false)
class ReferralControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/referrals/code: Lấy mã giới thiệu của người dùng")
    void getReferralCode_Success() throws Exception {
        mockMvc.perform(get("/api/v1/referrals/code")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.referralCode").isNotEmpty())
                .andExpect(jsonPath("$.data.referralUrl").isNotEmpty());
    }

    @Test
    @DisplayName("GET /api/v1/referrals/history: Lấy lịch sử giới thiệu bạn bè")
    void getReferralHistory_Success() throws Exception {
        mockMvc.perform(get("/api/v1/referrals/history")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalInvited").isNumber());
    }

    @Test
    @DisplayName("POST /api/v1/referrals/apply: Nhập mã giới thiệu bạn bè")
    void applyReferral_Success() throws Exception {
        mockMvc.perform(post("/api/v1/referrals/apply")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", "SEN8899"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}

