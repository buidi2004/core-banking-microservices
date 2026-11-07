package com.fintech.notification.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.dto.TestPushRequest;
import com.fintech.notification.service.NotificationOpsService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = NotificationOpsController.class)
@AutoConfigureMockMvc(addFilters = false)
class NotificationOpsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private NotificationOpsService opsService;

    @Test
    @DisplayName("GET /api/v1/notifications/ops/dlq/stats - Cho phép ROLE_MANAGER")
    void getDlqStats_manager_success() throws Exception {
        when(opsService.getDlqStats()).thenReturn(Map.of("dlqMessageCount", 3L));

        mockMvc.perform(get("/api/v1/notifications/ops/dlq/stats")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.dlqMessageCount").value(3));
    }

    @Test
    @DisplayName("GET /api/v1/notifications/ops/dlq/stats - Chặn nếu không phải Quản lý")
    void getDlqStats_forbiddenForUser() throws Exception {
        mockMvc.perform(get("/api/v1/notifications/ops/dlq/stats")
                        .header("X-User-Role", "USER"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("POST /api/v1/notifications/ops/dlq/retry - Thử lại tin nhắn DLQ")
    void retryDlq_success() throws Exception {
        when(opsService.retryDlqMessages(eq(50), eq("manager-01")))
                .thenReturn(Map.of("reprocessedCount", 5, "remainingCount", 0L));

        mockMvc.perform(post("/api/v1/notifications/ops/dlq/retry")
                        .header("X-User-Id", "manager-01")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .param("maxMessages", "50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.reprocessedCount").value(5));
    }

    @Test
    @DisplayName("GET /api/v1/notifications/ops/providers/health - Trạng thái sức khỏe provider")
    void getProviderHealth_success() throws Exception {
        when(opsService.getProviderHealth()).thenReturn(Map.of(
                "fcm", Map.of("status", "UP"),
                "websocket", Map.of("status", "UP")
        ));

        mockMvc.perform(get("/api/v1/notifications/ops/providers/health")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.fcm.status").value("UP"));
    }

    @Test
    @DisplayName("POST /api/v1/notifications/ops/test-push - Gửi thông báo thử nghiệm")
    void testPush_success() throws Exception {
        TestPushRequest request = new TestPushRequest("user-01", "Tiêu đề", "Nội dung", "ALL");

        when(opsService.sendTestNotification(any(), eq("manager-01")))
                .thenReturn(Map.of("success", true, "targetUserId", "user-01"));

        mockMvc.perform(post("/api/v1/notifications/ops/test-push")
                        .header("X-User-Id", "manager-01")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.targetUserId").value("user-01"));
    }
}
