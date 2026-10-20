package com.fintech.payment.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ConfigLimitController.class)
@AutoConfigureMockMvc(addFilters = false)
class ConfigLimitControllerTest {

    @Autowired
    private MockMvc mockMvc;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/config/limits: Lấy danh sách định mức hạn mức theo cấp bậc eKYC")
    void getLimits_Success() throws Exception {
        mockMvc.perform(get("/api/v1/config/limits"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.tiers[0].tier").value("BASIC"))
                .andExpect(jsonPath("$.data.tiers[1].tier").value("VERIFIED"));
    }

    @Test
    @DisplayName("GET /api/v1/config/limits/status: Lấy trạng thái hạn mức của người dùng hiện tại")
    void getLimitStatus_Success() throws Exception {
        mockMvc.perform(get("/api/v1/config/limits/status")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.userId").value(userId))
                .andExpect(jsonPath("$.data.remainingDaily").isNumber());
    }
}

