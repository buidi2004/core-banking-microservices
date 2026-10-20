package com.fintech.identity.controller;

import com.fintech.identity.dto.UserProfileResponse;
import com.fintech.identity.service.UserService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = UserController.class)
@AutoConfigureMockMvc(addFilters = false)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    @DisplayName("GET /api/v1/users/me - Trích xuất chính xác X-User-Id do API Gateway inject")
    void shouldExtractUserIdHeaderInjectedByGateway() throws Exception {
        String testUserId = "usr-test-123456";

        UserProfileResponse mockProfile = UserProfileResponse.builder()
                .userId(testUserId)
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .role("ROLE_USER")
                .kycTier("VERIFIED")
                .build();

        when(userService.getProfile(testUserId)).thenReturn(mockProfile);

        mockMvc.perform(get("/api/v1/users/me")
                        .header("X-User-Id", testUserId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.userId", is(testUserId)))
                .andExpect(jsonPath("$.data.fullName", is("Nguyen Van A")))
                .andExpect(jsonPath("$.data.kycTier", is("VERIFIED")));

        verify(userService).getProfile(testUserId);
    }
}
