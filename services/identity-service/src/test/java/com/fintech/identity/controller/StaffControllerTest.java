package com.fintech.identity.controller;

import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.service.StaffService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = StaffController.class)
@AutoConfigureMockMvc(addFilters = false)
class StaffControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private StaffService staffService;

    @Test
    @DisplayName("GET /api/v1/staff/branch/{branchId} - Lấy danh sách cán bộ chi nhánh thành công")
    void shouldReturnStaffListForBranch() throws Exception {
        StaffResponse teller1 = StaffResponse.builder()
                .id("t0000001-0000-0000-0000-000000000001")
                .username("teller1")
                .fullName("Teller Nguyễn Văn A")
                .phoneNumber("0911000001")
                .email("teller1@banking.example.com")
                .role("ROLE_TELLER")
                .roles(List.of("ROLE_TELLER"))
                .branchId("BR_Q1")
                .status("ACTIVE")
                .kycTier("VERIFIED")
                .build();

        StaffResponse manager1 = StaffResponse.builder()
                .id("m0000001-0000-0000-0000-000000000001")
                .username("manager1")
                .fullName("Manager Lê Hoàng C")
                .phoneNumber("0911000003")
                .email("manager1@banking.example.com")
                .role("ROLE_MANAGER")
                .roles(List.of("ROLE_MANAGER"))
                .branchId("BR_Q1")
                .status("ACTIVE")
                .kycTier("VERIFIED")
                .build();

        when(staffService.getStaffByBranch("BR_Q1")).thenReturn(List.of(teller1, manager1));

        mockMvc.perform(get("/api/v1/staff/branch/BR_Q1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(2)))
                .andExpect(jsonPath("$.data[0].username", is("teller1")))
                .andExpect(jsonPath("$.data[0].role", is("ROLE_TELLER")))
                .andExpect(jsonPath("$.data[0].branchId", is("BR_Q1")))
                .andExpect(jsonPath("$.data[1].username", is("manager1")))
                .andExpect(jsonPath("$.data[1].role", is("ROLE_MANAGER")))
                .andExpect(jsonPath("$.data[1].branchId", is("BR_Q1")));
    }

    @Test
    @DisplayName("GET /api/v1/staff/branch/{branchId} - Trả về mảng rỗng khi chi nhánh không có cán bộ")
    void shouldReturnEmptyListWhenBranchHasNoStaff() throws Exception {
        when(staffService.getStaffByBranch("BR_UNKNOWN")).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/staff/branch/BR_UNKNOWN")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(0)));
    }
}
