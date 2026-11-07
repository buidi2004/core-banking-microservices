package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.identity.dto.*;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = StaffController.class)
@AutoConfigureMockMvc(addFilters = false)
class StaffControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

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
                        .header("X-User-Role", "ROLE_MANAGER")
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
                        .header("X-User-Role", "ROLE_TELLER")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    @Test
    @DisplayName("GET /api/v1/staff - Chặn người dùng thường (ROLE_USER) xem danh sách cán bộ")
    void shouldBlockStaffListForRegularUser() throws Exception {
        mockMvc.perform(get("/api/v1/staff")
                        .header("X-User-Role", "ROLE_USER")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("POST /api/v1/staff - Tạo mới cán bộ khi có quyền Manager")
    void shouldCreateStaffWhenAuthorized() throws Exception {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .username("teller_hanoi")
                .phoneNumber("0988112233")
                .fullName("Trần Thị B")
                .email("hanoi@banking.example.com")
                .role("ROLE_TELLER")
                .branchId("BR_HK")
                .build();

        StaffResponse res = StaffResponse.builder()
                .id("new-id-123")
                .username("teller_hanoi")
                .fullName("Trần Thị B")
                .role("ROLE_TELLER")
                .branchId("BR_HK")
                .status("ACTIVE")
                .build();

        when(staffService.createStaff(any(CreateStaffRequest.class), anyString(), anyString())).thenReturn(res);

        mockMvc.perform(post("/api/v1/staff")
                        .header("X-User-Id", "admin_01")
                        .header("X-User-Role", "ROLE_ADMIN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.username", is("teller_hanoi")))
                .andExpect(jsonPath("$.data.role", is("ROLE_TELLER")));
    }

    @Test
    @DisplayName("POST /api/v1/staff - Trả về 403 Forbidden khi người dùng không phải Quản lý/Admin")
    void shouldReturnForbiddenWhenCreatingStaffWithoutRole() throws Exception {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .username("teller_hanoi")
                .phoneNumber("0988112233")
                .fullName("Trần Thị B")
                .email("hanoi@banking.example.com")
                .role("ROLE_TELLER")
                .branchId("BR_HK")
                .build();

        mockMvc.perform(post("/api/v1/staff")
                        .header("X-User-Id", "user_01")
                        .header("X-User-Role", "ROLE_USER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("POST /api/v1/staff/{id}/lock - Khóa tài khoản cán bộ")
    void shouldLockStaff() throws Exception {
        LockStaffRequest req = new LockStaffRequest("Tạm đình chỉ công tác");
        StaffResponse res = StaffResponse.builder()
                .id("staff_01")
                .username("teller1")
                .status("BLOCKED")
                .build();

        when(staffService.lockStaff(anyString(), any(LockStaffRequest.class), anyString(), anyString())).thenReturn(res);

        mockMvc.perform(post("/api/v1/staff/staff_01/lock")
                        .header("X-User-Id", "manager_01")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("BLOCKED")));
    }

    @Test
    @DisplayName("POST /api/v1/staff/{id}/unlock - Mở khóa tài khoản cán bộ")
    void shouldUnlockStaff() throws Exception {
        StaffResponse res = StaffResponse.builder()
                .id("staff_01")
                .username("teller1")
                .status("ACTIVE")
                .build();

        when(staffService.unlockStaff(anyString(), anyString(), anyString())).thenReturn(res);

        mockMvc.perform(post("/api/v1/staff/staff_01/unlock")
                        .header("X-User-Id", "manager_01")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("ACTIVE")));
    }
}
