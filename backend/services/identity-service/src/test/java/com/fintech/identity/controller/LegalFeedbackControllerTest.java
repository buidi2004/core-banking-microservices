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

@WebMvcTest(controllers = {LegalController.class, FeedbackController.class})
@AutoConfigureMockMvc(addFilters = false)
class LegalFeedbackControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/legal/terms: Lấy điều khoản sử dụng và chính sách bảo mật")
    void getLegalTerms_Success() throws Exception {
        mockMvc.perform(get("/api/v1/legal/terms"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.termsOfService").isNotEmpty());
    }

    @Test
    @DisplayName("POST /api/v1/legal/consent: Đồng thuận chính sách")
    void consentLegal_Success() throws Exception {
        mockMvc.perform(post("/api/v1/legal/consent")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("agreed", true, "version", "2.0"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("POST /api/v1/feedback: Gửi ý kiến phản hồi")
    void submitFeedback_Success() throws Exception {
        mockMvc.perform(post("/api/v1/feedback")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 5, "comment", "Ứng dụng tuyệt vời!"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}

