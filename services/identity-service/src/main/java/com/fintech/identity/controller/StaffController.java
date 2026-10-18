package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.service.StaffService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller quản lý và tra cứu thông tin cán bộ ngân hàng (Teller, Manager).
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/staff")
@RequiredArgsConstructor
public class StaffController {

    private final StaffService staffService;

    /**
     * Endpoint GET /api/v1/staff/branch/{branchId}
     * Lấy danh sách toàn bộ cán bộ ngân hàng thuộc chi nhánh cụ thể.
     *
     * @param branchId Mã chi nhánh (ví dụ: BR_Q1, BR_HK)
     * @return ApiResponse danh sách cán bộ
     */
    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<StaffResponse>>> getStaffByBranch(@PathVariable String branchId) {
        log.info("Nhận yêu cầu tra cứu cán bộ chi nhánh: {}", branchId);
        List<StaffResponse> staffList = staffService.getStaffByBranch(branchId);
        return ResponseEntity.ok(ApiResponse.ok(staffList, "Lấy danh sách cán bộ chi nhánh thành công"));
    }
}
