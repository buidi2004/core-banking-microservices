package com.fintech.wallet.presentation.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.in.DeviceTokenUseCase;
import com.fintech.wallet.presentation.request.RegisterDeviceTokenRequest;
import com.fintech.wallet.presentation.request.UnregisterDeviceTokenRequest;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DeviceController.class)
class DeviceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private DeviceTokenUseCase deviceTokenUseCase;

    @MockBean
    private com.fintech.wallet.infrastructure.security.RedisRateLimiter redisRateLimiter;

    @MockBean
    private com.fintech.wallet.infrastructure.security.JwtTokenProvider jwtTokenProvider;

    @MockBean
    private com.fintech.wallet.domain.port.in.SessionManagementUseCase sessionManagementUseCase;

    @MockBean
    private org.springframework.data.redis.core.RedisTemplate<String, Object> redisTemplate;

    @Test
    @WithMockUser(username = "user-123")
    void registerDeviceToken_validRequest_shouldReturnSuccess() throws Exception {
        RegisterDeviceTokenRequest request = new RegisterDeviceTokenRequest("fcm-token-123", "ANDROID");
        DeviceToken token = DeviceToken.createNew("user-123", "fcm-token-123", "ANDROID");

        Mockito.when(deviceTokenUseCase.registerDeviceToken(eq("user-123"), eq("fcm-token-123"), eq("ANDROID")))
                .thenReturn(token);

        mockMvc.perform(post("/api/v1/devices/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Device token registered successfully"))
                .andExpect(jsonPath("$.data.fcmToken").value("fcm-token-123"))
                .andExpect(jsonPath("$.data.userId").value("user-123"));
    }

    @Test
    @WithMockUser(username = "user-123")
    void registerDeviceToken_blankFcmToken_shouldReturnBadRequest() throws Exception {
        RegisterDeviceTokenRequest request = new RegisterDeviceTokenRequest("", "ANDROID");

        mockMvc.perform(post("/api/v1/devices/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "user-123")
    void unregisterDeviceToken_withBody_shouldReturnSuccess() throws Exception {
        UnregisterDeviceTokenRequest request = new UnregisterDeviceTokenRequest("fcm-token-123");

        mockMvc.perform(delete("/api/v1/devices/unregister")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Device token unregistered successfully"));

        Mockito.verify(deviceTokenUseCase).unregisterDeviceToken(eq("user-123"), eq("fcm-token-123"));
    }

    @Test
    @WithMockUser(username = "user-123")
    void unregisterDeviceToken_withQueryParam_shouldReturnSuccess() throws Exception {
        mockMvc.perform(delete("/api/v1/devices/unregister")
                        .with(csrf())
                        .param("fcmToken", "fcm-token-param"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        Mockito.verify(deviceTokenUseCase).unregisterDeviceToken(eq("user-123"), eq("fcm-token-param"));
    }
}
