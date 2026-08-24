package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.model.NotificationType;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import com.fintech.wallet.presentation.response.PageResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(NotificationController.class)
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private NotificationUseCase notificationUseCase;

    @MockBean
    private com.fintech.wallet.infrastructure.security.RedisRateLimiter redisRateLimiter;

    @MockBean
    private com.fintech.wallet.infrastructure.security.JwtTokenProvider jwtTokenProvider;

    @MockBean
    private com.fintech.wallet.domain.port.in.SessionManagementUseCase sessionManagementUseCase;

    @MockBean
    private org.springframework.data.redis.core.RedisTemplate<String, Object> redisTemplate;

    private final String userId = "testUser";

    @Test
    @WithMockUser(username = "testUser")
    void getNotifications_shouldReturnSuccess() throws Exception {
        NotificationInfo info = NotificationInfo.createNew(userId, "Title", "Body", NotificationType.BALANCE, null);
        PageResponse<NotificationInfo> mockResponse = PageResponse.of(List.of(info), 0, 20, 1);
        
        Mockito.when(notificationUseCase.getNotifications(eq(userId), isNull(), eq(0), eq(20)))
               .thenReturn(mockResponse);

        mockMvc.perform(get("/api/v1/notifications")
                .param("page", "0")
                .param("size", "20")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].title").value("Title"));
    }

    @Test
    @WithMockUser(username = "testUser")
    void markAsRead_shouldReturnSuccess() throws Exception {
        mockMvc.perform(patch("/api/v1/notifications/notif123/read")
                .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        Mockito.verify(notificationUseCase).markAsRead(userId, "notif123");
    }

    @Test
    @WithMockUser(username = "testUser")
    void markAllAsRead_shouldReturnSuccess() throws Exception {
        mockMvc.perform(patch("/api/v1/notifications/read-all")
                .param("type", "BALANCE")
                .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        Mockito.verify(notificationUseCase).markAllAsRead(userId, "BALANCE");
    }
}