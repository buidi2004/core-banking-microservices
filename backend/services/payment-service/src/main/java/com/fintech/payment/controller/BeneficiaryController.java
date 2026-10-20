package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.BeneficiaryDto;
import com.fintech.payment.dto.CreateBeneficiaryRequest;
import com.fintech.payment.service.BeneficiaryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/beneficiaries")
public class BeneficiaryController {

    private final BeneficiaryService beneficiaryService;

    public BeneficiaryController(BeneficiaryService beneficiaryService) {
        this.beneficiaryService = beneficiaryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BeneficiaryDto>>> getBeneficiaries(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<BeneficiaryDto> list = beneficiaryService.getBeneficiaries(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh bạ người thụ hưởng", list));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BeneficiaryDto>> addBeneficiary(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @RequestBody CreateBeneficiaryRequest request) {
        BeneficiaryDto res = beneficiaryService.addBeneficiary(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Đã thêm người thụ hưởng vào danh bạ", res));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBeneficiary(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String id) {
        beneficiaryService.deleteBeneficiary(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Đã xóa người thụ hưởng", null));
    }
}

