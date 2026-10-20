package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StaffServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private StaffService staffService;

    @Test
    @DisplayName("Lấy danh sách cán bộ chi nhánh BR_Q1 trả về Teller và Manager")
    void shouldReturnStaffForBranchQ1() {
        UserEntity teller = UserEntity.builder()
                .id("t0000001-0000-0000-0000-000000000001")
                .username("teller1")
                .phoneNumber("0911000001")
                .fullName("Teller Nguyễn Văn A")
                .email("teller1@banking.example.com")
                .role("ROLE_TELLER")
                .branchId("BR_Q1")
                .status("ACTIVE")
                .kycTier("VERIFIED")
                .build();

        UserEntity manager = UserEntity.builder()
                .id("m0000001-0000-0000-0000-000000000001")
                .username("manager1")
                .phoneNumber("0911000003")
                .fullName("Manager Lê Hoàng C")
                .email("manager1@banking.example.com")
                .role("ROLE_MANAGER")
                .branchId("BR_Q1")
                .status("ACTIVE")
                .kycTier("VERIFIED")
                .build();

        when(userRepository.findStaffByBranchId("BR_Q1")).thenReturn(List.of(teller, manager));

        List<StaffResponse> staffList = staffService.getStaffByBranch("BR_Q1");

        assertNotNull(staffList);
        assertEquals(2, staffList.size());
        assertEquals("teller1", staffList.get(0).getUsername());
        assertEquals("ROLE_TELLER", staffList.get(0).getRole());
        assertEquals("BR_Q1", staffList.get(0).getBranchId());
        assertEquals("manager1", staffList.get(1).getUsername());
        assertEquals("ROLE_MANAGER", staffList.get(1).getRole());
        assertEquals("BR_Q1", staffList.get(1).getBranchId());
    }

    @Test
    @DisplayName("Ném ngoại lệ khi branchId rỗng hoặc null")
    void shouldThrowExceptionWhenBranchIdIsBlank() {
        assertThrows(IllegalArgumentException.class, () -> staffService.getStaffByBranch(""));
        assertThrows(IllegalArgumentException.class, () -> staffService.getStaffByBranch(null));
    }
}
