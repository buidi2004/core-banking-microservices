package com.fintech.identity.service;

import com.fintech.common.audit.AuditEvent;
import com.fintech.identity.audit.AuditEventPublisher;
import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.CreateStaffRequest;
import com.fintech.identity.dto.LockStaffRequest;
import com.fintech.identity.dto.ResetStaffPasswordRequest;
import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.dto.UpdateStaffRequest;
import com.fintech.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class StaffService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditEventPublisher auditEventPublisher;

    @Transactional(readOnly = true)
    public List<StaffResponse> getStaffByBranch(String branchId) {
        if (branchId == null || branchId.isBlank()) {
            throw new IllegalArgumentException("Mã chi nhánh (branchId) không được để trống.");
        }
        String cleanBranchId = branchId.trim();
        log.info("Truy vấn danh sách cán bộ cho chi nhánh: {}", cleanBranchId);

        List<UserEntity> staffEntities = userRepository.findStaffByBranchId(cleanBranchId);
        return staffEntities.stream()
                .map(StaffResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StaffResponse> getAllStaff() {
        return userRepository.findAllStaff().stream()
                .map(StaffResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StaffResponse> getStaffFiltered(String branchId, String role, String status) {
        // Chuẩn hoá chữ hoa tại đây thay vì UPPER() trên tham số nullable trong JPQL
        // (PostgreSQL JDBC bind null thành bytea -> lỗi "function upper(bytea) does not exist").
        String cleanBranch = (branchId != null && !branchId.isBlank() && !"ALL".equalsIgnoreCase(branchId.trim()))
                ? branchId.trim().toUpperCase() : null;
        String cleanRole = (role != null && !role.isBlank() && !"ALL".equalsIgnoreCase(role.trim()))
                ? role.trim().toUpperCase() : null;
        String roleWithPrefix = cleanRole != null ? "ROLE_" + cleanRole : null;
        String cleanStatus = (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status.trim()))
                ? status.trim().toUpperCase() : null;

        return userRepository.findStaffFiltered(cleanBranch, cleanRole, roleWithPrefix, cleanStatus).stream()
                .map(StaffResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public StaffResponse getStaffById(String staffId) {
        UserEntity user = findStaffEntity(staffId);
        return StaffResponse.fromEntity(user);
    }

    @Transactional
    public StaffResponse createStaff(CreateStaffRequest request, String actorId, String actorRole) {
        String cleanUsername = request.getUsername().trim().toLowerCase();
        String cleanPhone = request.getPhoneNumber().trim();
        String cleanEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsername(cleanUsername)) {
            throw new IllegalArgumentException("Tên đăng nhập '" + cleanUsername + "' đã tồn tại.");
        }
        if (userRepository.existsByPhoneNumber(cleanPhone)) {
            throw new IllegalArgumentException("Số điện thoại '" + cleanPhone + "' đã được sử dụng.");
        }
        if (userRepository.existsByEmail(cleanEmail)) {
            throw new IllegalArgumentException("Email '" + cleanEmail + "' đã được sử dụng.");
        }

        String normalizedRole = normalizeRole(request.getRole());
        String initialPassword = (request.getInitialPassword() != null && !request.getInitialPassword().isBlank())
                ? request.getInitialPassword().trim() : "Staff@123456";

        UserEntity staff = UserEntity.builder()
                .id(UUID.randomUUID().toString())
                .username(cleanUsername)
                .phoneNumber(cleanPhone)
                .fullName(request.getFullName().trim())
                .email(cleanEmail)
                .role(normalizedRole)
                .branchId(request.getBranchId().trim())
                .passwordHash(passwordEncoder.encode(initialPassword))
                .status("ACTIVE")
                .kycTier("VERIFIED")
                .pinFailedAttempts(0)
                .build();

        staff = userRepository.save(staff);
        log.info("Tạo mới cán bộ ngân hàng thành công: id={}, username={}, role={}, branch={}",
                staff.getId(), staff.getUsername(), staff.getRole(), staff.getBranchId());

        publishAudit("CREATE_STAFF", staff.getId(), actorId, actorRole, staff.getBranchId(),
                Map.of(),
                Map.of("username", staff.getUsername(), "role", staff.getRole(), "branchId", staff.getBranchId()),
                "Tạo mới tài khoản cán bộ ngân hàng");

        return StaffResponse.fromEntity(staff);
    }

    @Transactional
    public StaffResponse updateStaff(String staffId, UpdateStaffRequest request, String actorId, String actorRole) {
        UserEntity staff = findStaffEntity(staffId);
        String cleanEmail = request.getEmail().trim().toLowerCase();

        if (!cleanEmail.equalsIgnoreCase(staff.getEmail()) && userRepository.existsByEmail(cleanEmail)) {
            throw new IllegalArgumentException("Email '" + cleanEmail + "' đã được sử dụng bởi người dùng khác.");
        }

        Map<String, Object> before = Map.of(
                "fullName", staff.getFullName() != null ? staff.getFullName() : "",
                "email", staff.getEmail() != null ? staff.getEmail() : "",
                "role", staff.getRole() != null ? staff.getRole() : "",
                "branchId", staff.getBranchId() != null ? staff.getBranchId() : ""
        );

        staff.setFullName(request.getFullName().trim());
        staff.setEmail(cleanEmail);
        staff.setRole(normalizeRole(request.getRole()));
        staff.setBranchId(request.getBranchId().trim());

        staff = userRepository.save(staff);
        log.info("Cập nhật thông tin cán bộ thành công: id={}, role={}, branch={}",
                staff.getId(), staff.getRole(), staff.getBranchId());

        publishAudit("UPDATE_STAFF", staff.getId(), actorId, actorRole, staff.getBranchId(),
                before,
                Map.of("fullName", staff.getFullName(), "email", staff.getEmail(), "role", staff.getRole(), "branchId", staff.getBranchId()),
                "Cập nhật vai trò / chi nhánh cán bộ ngân hàng");

        return StaffResponse.fromEntity(staff);
    }

    @Transactional
    public StaffResponse lockStaff(String staffId, LockStaffRequest request, String actorId, String actorRole) {
        if (staffId.equalsIgnoreCase(actorId)) {
            throw new IllegalArgumentException("Quản trị viên không thể tự khóa tài khoản của chính mình.");
        }

        UserEntity staff = findStaffEntity(staffId);
        String previousStatus = staff.getStatus();
        staff.setStatus("BLOCKED");

        staff = userRepository.save(staff);
        log.warn("Đã khóa tài khoản cán bộ: id={}, username={}, lý do: {}", staff.getId(), staff.getUsername(), request.getReason());

        publishAudit("LOCK_STAFF", staff.getId(), actorId, actorRole, staff.getBranchId(),
                Map.of("status", previousStatus),
                Map.of("status", "BLOCKED"),
                request.getReason());

        return StaffResponse.fromEntity(staff);
    }

    @Transactional
    public StaffResponse unlockStaff(String staffId, String actorId, String actorRole) {
        UserEntity staff = findStaffEntity(staffId);
        String previousStatus = staff.getStatus();
        staff.setStatus("ACTIVE");
        staff.setPinFailedAttempts(0);
        staff.setPinLockedUntil(null);

        staff = userRepository.save(staff);
        log.info("Đã mở khóa tài khoản cán bộ: id={}, username={}", staff.getId(), staff.getUsername());

        publishAudit("UNLOCK_STAFF", staff.getId(), actorId, actorRole, staff.getBranchId(),
                Map.of("status", previousStatus),
                Map.of("status", "ACTIVE"),
                "Mở khóa tài khoản cán bộ sau kiểm tra");

        return StaffResponse.fromEntity(staff);
    }

    @Transactional
    public StaffResponse resetPassword(String staffId, ResetStaffPasswordRequest request, String actorId, String actorRole) {
        UserEntity staff = findStaffEntity(staffId);
        staff.setPasswordHash(passwordEncoder.encode(request.getNewPassword().trim()));
        staff.setPinFailedAttempts(0);
        staff.setPinLockedUntil(null);

        staff = userRepository.save(staff);
        log.info("Đặt lại mật khẩu cho cán bộ: id={}, username={}", staff.getId(), staff.getUsername());

        publishAudit("RESET_STAFF_PASSWORD", staff.getId(), actorId, actorRole, staff.getBranchId(),
                Map.of(),
                Map.of("passwordReset", true),
                "Đặt lại mật khẩu cấp quyền bởi Quản trị viên");

        return StaffResponse.fromEntity(staff);
    }

    private UserEntity findStaffEntity(String staffId) {
        return userRepository.findById(staffId)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy thông tin cán bộ với ID: " + staffId));
    }

    private String normalizeRole(String rawRole) {
        if (rawRole == null || rawRole.isBlank()) {
            return "ROLE_TELLER";
        }
        String clean = rawRole.trim().toUpperCase();
        if ("TELLER".equals(clean)) return "ROLE_TELLER";
        if ("MANAGER".equals(clean)) return "ROLE_MANAGER";
        if ("ADMIN".equals(clean)) return "ROLE_ADMIN";
        if (!clean.startsWith("ROLE_")) {
            return "ROLE_" + clean;
        }
        return clean;
    }

    private void publishAudit(String action, String staffId, String actorId, String actorRole, String branchId,
                              Map<String, Object> before, Map<String, Object> after, String reason) {
        if (auditEventPublisher != null) {
            try {
                auditEventPublisher.publish(new AuditEvent(
                        UUID.randomUUID(),
                        Instant.now(),
                        "identity-service",
                        action,
                        "STAFF",
                        staffId,
                        actorId != null && !actorId.isBlank() ? actorId : "SYSTEM",
                        actorRole != null && !actorRole.isBlank() ? actorRole : "ROLE_ADMIN",
                        branchId != null && !branchId.isBlank() ? branchId : "HEAD_OFFICE",
                        UUID.randomUUID().toString(),
                        "127.0.0.1",
                        "PORTAL",
                        before,
                        after,
                        reason
                ));
            } catch (Exception e) {
                log.warn("Không thể xuất audit event cho action {}: {}", action, e.getMessage());
            }
        }
    }
}
