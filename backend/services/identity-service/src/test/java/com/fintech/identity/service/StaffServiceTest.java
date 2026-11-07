package com.fintech.identity.service;

import com.fintech.identity.audit.AuditEventPublisher;
import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.*;
import com.fintech.identity.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StaffServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuditEventPublisher auditEventPublisher;

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

    @Test
    @DisplayName("Tạo mới cán bộ ngân hàng thành công")
    void shouldCreateStaffSuccessfully() {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .username("teller_new")
                .phoneNumber("0988776655")
                .fullName("Nguyễn Thị Mới")
                .email("newteller@banking.com")
                .role("TELLER")
                .branchId("BR_Q1")
                .initialPassword("Secret@123")
                .build();

        when(userRepository.existsByUsername("teller_new")).thenReturn(false);
        when(userRepository.existsByPhoneNumber("0988776655")).thenReturn(false);
        when(userRepository.existsByEmail("newteller@banking.com")).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed_password");
        when(userRepository.save(any(UserEntity.class))).thenAnswer(i -> i.getArgument(0));

        StaffResponse res = staffService.createStaff(req, "admin_user", "ROLE_ADMIN");

        assertNotNull(res);
        assertEquals("teller_new", res.getUsername());
        assertEquals("ROLE_TELLER", res.getRole());
        assertEquals("BR_Q1", res.getBranchId());
        assertEquals("ACTIVE", res.getStatus());
        verify(userRepository, times(1)).save(any(UserEntity.class));
    }

    @Test
    @DisplayName("Tạo mới thất bại nếu username đã tồn tại")
    void shouldFailCreateStaffWhenUsernameExists() {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .username("teller1")
                .phoneNumber("0988776655")
                .fullName("Nguyễn Thị Mới")
                .email("newteller@banking.com")
                .role("TELLER")
                .branchId("BR_Q1")
                .build();

        when(userRepository.existsByUsername("teller1")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () ->
                staffService.createStaff(req, "admin_user", "ROLE_ADMIN"));
    }

    @Test
    @DisplayName("Khóa tài khoản cán bộ thành công")
    void shouldLockStaffSuccessfully() {
        UserEntity staff = UserEntity.builder()
                .id("staff-123")
                .username("teller1")
                .status("ACTIVE")
                .branchId("BR_Q1")
                .build();

        when(userRepository.findById("staff-123")).thenReturn(Optional.of(staff));
        when(userRepository.save(any(UserEntity.class))).thenAnswer(i -> i.getArgument(0));

        LockStaffRequest req = new LockStaffRequest("Tạm dừng do điều tra");
        StaffResponse res = staffService.lockStaff("staff-123", req, "admin_user", "ROLE_ADMIN");

        assertEquals("BLOCKED", res.getStatus());
        verify(userRepository, times(1)).save(staff);
    }

    @Test
    @DisplayName("Không được tự khóa tài khoản của chính mình")
    void shouldRejectSelfLock() {
        LockStaffRequest req = new LockStaffRequest("Tự khóa");
        assertThrows(IllegalArgumentException.class, () ->
                staffService.lockStaff("admin-user", req, "admin-user", "ROLE_ADMIN"));
    }

    @Test
    @DisplayName("Mở khóa tài khoản cán bộ thành công")
    void shouldUnlockStaffSuccessfully() {
        UserEntity staff = UserEntity.builder()
                .id("staff-123")
                .username("teller1")
                .status("BLOCKED")
                .pinFailedAttempts(3)
                .branchId("BR_Q1")
                .build();

        when(userRepository.findById("staff-123")).thenReturn(Optional.of(staff));
        when(userRepository.save(any(UserEntity.class))).thenAnswer(i -> i.getArgument(0));

        StaffResponse res = staffService.unlockStaff("staff-123", "admin_user", "ROLE_ADMIN");

        assertEquals("ACTIVE", res.getStatus());
        assertEquals(0, staff.getPinFailedAttempts());
        assertNull(staff.getPinLockedUntil());
    }

    @Test
    @DisplayName("Đặt lại mật khẩu cho cán bộ thành công")
    void shouldResetPasswordSuccessfully() {
        UserEntity staff = UserEntity.builder()
                .id("staff-123")
                .username("teller1")
                .passwordHash("old_hash")
                .branchId("BR_Q1")
                .build();

        when(userRepository.findById("staff-123")).thenReturn(Optional.of(staff));
        when(passwordEncoder.encode("NewPass@123")).thenReturn("new_encoded_hash");
        when(userRepository.save(any(UserEntity.class))).thenAnswer(i -> i.getArgument(0));

        StaffResponse res = staffService.resetPassword("staff-123", new ResetStaffPasswordRequest("NewPass@123"), "admin_user", "ROLE_ADMIN");

        assertNotNull(res);
        assertEquals("new_encoded_hash", staff.getPasswordHash());
    }
}
