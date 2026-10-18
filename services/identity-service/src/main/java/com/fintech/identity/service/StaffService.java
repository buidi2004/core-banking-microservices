package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.StaffResponse;
import com.fintech.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class StaffService {

    private final UserRepository userRepository;

    /**
     * Lấy danh sách cán bộ ngân hàng (Teller, Manager, Admin...) thuộc chi nhánh.
     *
     * @param branchId Mã chi nhánh (ví dụ: BR_Q1, BR_HK)
     * @return Danh sách cán bộ StaffResponse
     */
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
}
