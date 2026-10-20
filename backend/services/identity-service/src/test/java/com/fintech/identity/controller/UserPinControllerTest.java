package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.identity.dto.PinSetRequest;
import com.fintech.identity.dto.PinVerifyRequest;
import com.fintech.identity.dto.PinVerifyResponse;
import com.fintech.identity.exception.InvalidPinException;
import com.fintech.identity.exception.PinLockedException;
import com.fintech.identity.exception.PinNotSetException;
import com.fintech.identity.service.UserPinService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserPinController.class)
@AutoConfigureMockMvc(addFilters = false)
class UserPinControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserPinService userPinService;

    @Test
    @DisplayName("POST /api/v1/users/pin/set: Thiết lập mã PIN thành công")
    void testSetPin_Success() throws Exception {
        PinSetRequest request = new PinSetRequest("123456");

        mockMvc.perform(post("/api/v1/users/pin/set")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Thiết lập mã PIN giao dịch thành công"));

        verify(userPinService).setPin("user-123", "123456");
    }

    @Test
    @DisplayName("POST /api/v1/users/pin/verify: Xác thực đúng trả về pinToken")
    void testVerifyPin_Success() throws Exception {
        PinVerifyRequest request = new PinVerifyRequest("123456");
        when(userPinService.verifyPin("user-123", "123456"))
                .thenReturn(new PinVerifyResponse("sample-pin-token-123", 300L));

        mockMvc.perform(post("/api/v1/users/pin/verify")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value("sample-pin-token-123"));
    }

    @Test
    @DisplayName("POST /api/v1/users/pin/verify: Sai PIN trả về 400 kèm errorCode INVALID_PIN")
    void testVerifyPin_InvalidPin_ReturnsBadRequest() throws Exception {
        PinVerifyRequest request = new PinVerifyRequest("000000");
        doThrow(new InvalidPinException("Mã PIN không chính xác. Bạn còn 3 lần thử", 3))
                .when(userPinService).verifyPin("user-123", "000000");

        mockMvc.perform(post("/api/v1/users/pin/verify")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INVALID_PIN"))
                .andExpect(jsonPath("$.message").value("Mã PIN không chính xác. Bạn còn 3 lần thử"));
    }

    @Test
    @DisplayName("POST /api/v1/users/pin/verify: Bị khóa trả về 400 kèm errorCode PIN_LOCKED")
    void testVerifyPin_Locked_ReturnsBadRequest() throws Exception {
        PinVerifyRequest request = new PinVerifyRequest("123456");
        doThrow(new PinLockedException("Mã PIN đang bị khóa, vui lòng thử lại sau"))
                .when(userPinService).verifyPin("user-123", "123456");

        mockMvc.perform(post("/api/v1/users/pin/verify")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("PIN_LOCKED"));
    }

    @Test
    @DisplayName("POST /api/v1/users/pin/verify: Chưa cài PIN trả về 400 kèm errorCode PIN_NOT_SET")
    void testVerifyPin_NotSet_ReturnsBadRequest() throws Exception {
        PinVerifyRequest request = new PinVerifyRequest("123456");
        doThrow(new PinNotSetException("Mã PIN giao dịch chưa được thiết lập"))
                .when(userPinService).verifyPin("user-123", "123456");

        mockMvc.perform(post("/api/v1/users/pin/verify")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("PIN_NOT_SET"));
    }
}

