package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.LoanService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/loans")
@RequiredArgsConstructor
public class LoanController {

    private final LoanService loanService;

    @GetMapping("/products")
    public ResponseEntity<ApiResponse<List<LoanProductDto>>> getProducts() {
        List<LoanProductDto> products = loanService.getProducts();
        return ResponseEntity.ok(ApiResponse.<List<LoanProductDto>>builder()
                .success(true)
                .message("Lấy danh sách gói vay thành công")
                .data(products)
                .build());
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<LoanApplicationResponse>> applyLoan(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @Valid @RequestBody LoanApplicationRequest request) {
        LoanApplicationResponse response = loanService.applyLoan(userId, request);
        return ResponseEntity.ok(ApiResponse.<LoanApplicationResponse>builder()
                .success(true)
                .message("Hồ sơ vay đã được tiếp nhận và giải ngân tự động")
                .data(response)
                .build());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<LoanApplicationResponse>>> getUserLoans(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId) {
        List<LoanApplicationResponse> list = loanService.getUserLoans(userId);
        return ResponseEntity.ok(ApiResponse.<List<LoanApplicationResponse>>builder()
                .success(true)
                .message("Lấy danh sách khoản vay thành công")
                .data(list)
                .build());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LoanApplicationResponse>> getLoanDetail(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id) {
        LoanApplicationResponse detail = loanService.getLoanDetail(id, userId);
        return ResponseEntity.ok(ApiResponse.<LoanApplicationResponse>builder()
                .success(true)
                .message("Lấy chi tiết khoản vay thành công")
                .data(detail)
                .build());
    }

    @GetMapping("/{id}/schedule")
    public ResponseEntity<ApiResponse<LoanScheduleResponse>> getLoanSchedule(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id) {
        LoanScheduleResponse schedule = loanService.getLoanSchedule(id, userId);
        return ResponseEntity.ok(ApiResponse.<LoanScheduleResponse>builder()
                .success(true)
                .message("Lấy lịch trả nợ thành công")
                .data(schedule)
                .build());
    }

    @PostMapping("/{id}/repay")
    public ResponseEntity<ApiResponse<LoanRepaymentResponse>> repayTerm(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id,
            @Valid @RequestBody LoanRepaymentRequest request) {
        LoanRepaymentResponse response = loanService.repayTerm(id, userId, request);
        return ResponseEntity.ok(ApiResponse.<LoanRepaymentResponse>builder()
                .success(true)
                .message(response.getMessage())
                .data(response)
                .build());
    }
}

