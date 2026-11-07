package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.CreateStaffRequest;
import com.fintech.identity.dto.LockStaffRequest;
import com.fintech.identity.dto.ResetStaffPasswordRequest;
import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.dto.UpdateStaffRequest;
import com.fintech.identity.service.StaffService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

/**
 * Controller quản lý và tra cứu thông tin cán bộ ngân hàng (Teller, Manager, Admin).
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/staff")
@RequiredArgsConstructor
public class StaffController {

    private final StaffService staffService;

    /**
     * GET /api/v1/staff
     * Lấy danh sách toàn bộ cán bộ hoặc lọc theo chi nhánh, vai trò, trạng thái.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<StaffResponse>>> getStaffList(
            @RequestHeader(value = "X-User-Role", required = false) String actorRole,
            @RequestParam(required = false) String branchId,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status) {
        requireStaffRole(actorRole);
        List<StaffResponse> staffList = staffService.getStaffFiltered(branchId, role, status);
        return ResponseEntity.ok(ApiResponse.ok(staffList, "Lấy danh sách cán bộ ngân hàng thành công"));
    }

    /**
     * GET /api/v1/staff/{id}
     * Chi tiết hồ sơ cán bộ ngân hàng.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<StaffResponse>> getStaffDetail(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole) {
        requireStaffRole(actorRole);
        StaffResponse staff = staffService.getStaffById(id);
        return ResponseEntity.ok(ApiResponse.ok(staff, "Chi tiết cán bộ ngân hàng"));
    }

    /**
     * GET /api/v1/staff/branch/{branchId}
     * Lấy danh sách toàn bộ cán bộ ngân hàng thuộc chi nhánh cụ thể.
     */
    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<StaffResponse>>> getStaffByBranch(
            @PathVariable String branchId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole) {
        requireStaffRole(actorRole);
        log.info("Nhận yêu cầu tra cứu cán bộ chi nhánh: {}", branchId);
        List<StaffResponse> staffList = staffService.getStaffByBranch(branchId);
        return ResponseEntity.ok(ApiResponse.ok(staffList, "Lấy danh sách cán bộ chi nhánh thành công"));
    }

    /**
     * POST /api/v1/staff
     * Tạo mới tài khoản cán bộ ngân hàng (Yêu cầu quyền Quản lý/Admin).
     */
    @PostMapping
    public ResponseEntity<ApiResponse<StaffResponse>> createStaff(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole,
            @Valid @RequestBody CreateStaffRequest request) {
        requireManagerOrAdmin(actorRole);
        StaffResponse created = staffService.createStaff(request, actorId, actorRole);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Tạo mới tài khoản cán bộ ngân hàng thành công"));
    }

    /**
     * PUT /api/v1/staff/{id}
     * Cập nhật thông tin cán bộ ngân hàng (Họ tên, email, vai trò, chi nhánh).
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<StaffResponse>> updateStaff(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole,
            @Valid @RequestBody UpdateStaffRequest request) {
        requireManagerOrAdmin(actorRole);
        StaffResponse updated = staffService.updateStaff(id, request, actorId, actorRole);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Cập nhật thông tin cán bộ thành công"));
    }

    /**
     * POST /api/v1/staff/{id}/lock
     * Khóa tài khoản cán bộ ngân hàng.
     */
    @PostMapping("/{id}/lock")
    public ResponseEntity<ApiResponse<StaffResponse>> lockStaff(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole,
            @Valid @RequestBody LockStaffRequest request) {
        requireManagerOrAdmin(actorRole);
        StaffResponse locked = staffService.lockStaff(id, request, actorId, actorRole);
        return ResponseEntity.ok(ApiResponse.ok(locked, "Đã khóa tài khoản cán bộ"));
    }

    /**
     * POST /api/v1/staff/{id}/unlock
     * Mở khóa tài khoản cán bộ ngân hàng.
     */
    @PostMapping("/{id}/unlock")
    public ResponseEntity<ApiResponse<StaffResponse>> unlockStaff(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole) {
        requireManagerOrAdmin(actorRole);
        StaffResponse unlocked = staffService.unlockStaff(id, actorId, actorRole);
        return ResponseEntity.ok(ApiResponse.ok(unlocked, "Đã mở khóa tài khoản cán bộ"));
    }

    /**
     * POST /api/v1/staff/{id}/reset-password
     * Đặt lại mật khẩu đăng nhập cho cán bộ ngân hàng.
     */
    @PostMapping("/{id}/reset-password")
    public ResponseEntity<ApiResponse<StaffResponse>> resetPassword(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String actorRole,
            @Valid @RequestBody ResetStaffPasswordRequest request) {
        requireManagerOrAdmin(actorRole);
        StaffResponse updated = staffService.resetPassword(id, request, actorId, actorRole);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Đặt lại mật khẩu cán bộ thành công"));
    }

    private void requireStaffRole(String role) {
        if (role == null || (!"ROLE_TELLER".equalsIgnoreCase(role.trim())
                && !"TELLER".equalsIgnoreCase(role.trim())
                && !"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim())
                && !"ROLE_ADMIN".equalsIgnoreCase(role.trim())
                && !"ADMIN".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Chỉ cán bộ ngân hàng (Teller, Manager, Admin) mới có quyền truy cập thông tin nhân sự."
            );
        }
    }

    private void requireManagerOrAdmin(String role) {
        if (role == null || (!"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim())
                && !"ROLE_ADMIN".equalsIgnoreCase(role.trim())
                && !"ADMIN".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Chỉ Quản lý (ROLE_MANAGER) hoặc Quản trị viên (ROLE_ADMIN) mới có quyền quản trị nhân sự."
            );
        }
    }
}
