package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.SavingsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/savings")
@RequiredArgsConstructor
public class SavingsController {

    private final SavingsService savingsService;

    @GetMapping("/products")
    public ResponseEntity<ApiResponse<List<SavingsProductDto>>> getProducts() {
        List<SavingsProductDto> products = savingsService.getProducts();
        return ResponseEntity.ok(ApiResponse.<List<SavingsProductDto>>builder()
                .success(true)
                .message("Lấy danh sách sản phẩm tiết kiệm thành công")
                .data(products)
                .build());
    }

    @PostMapping("/accounts")
    public ResponseEntity<ApiResponse<SavingsAccountResponse>> openSavings(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @Valid @RequestBody OpenSavingsRequest request) {
        SavingsAccountResponse response = savingsService.openSavings(userId, request);
        return ResponseEntity.ok(ApiResponse.<SavingsAccountResponse>builder()
                .success(true)
                .message("Mở sổ tiết kiệm thành công")
                .data(response)
                .build());
    }

    @GetMapping("/accounts")
    public ResponseEntity<ApiResponse<List<SavingsAccountResponse>>> getUserSavings(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId) {
        List<SavingsAccountResponse> list = savingsService.getUserSavings(userId);
        return ResponseEntity.ok(ApiResponse.<List<SavingsAccountResponse>>builder()
                .success(true)
                .message("Lấy danh sách sổ tiết kiệm thành công")
                .data(list)
                .build());
    }

    @GetMapping("/accounts/{id}")
    public ResponseEntity<ApiResponse<SavingsAccountResponse>> getSavingsDetail(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id) {
        SavingsAccountResponse detail = savingsService.getSavingsDetail(id, userId);
        return ResponseEntity.ok(ApiResponse.<SavingsAccountResponse>builder()
                .success(true)
                .message("Lấy chi tiết sổ tiết kiệm thành công")
                .data(detail)
                .build());
    }

    @PostMapping("/accounts/{id}/settle")
    public ResponseEntity<ApiResponse<SettleSavingsResponse>> settleSavings(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "user-me") String userId,
            @PathVariable("id") String id,
            @RequestBody(required = false) SettleSavingsRequest request) {
        SettleSavingsResponse response = savingsService.settleSavings(id, userId, request);
        return ResponseEntity.ok(ApiResponse.<SettleSavingsResponse>builder()
                .success(true)
                .message(response.getMessage())
                .data(response)
                .build());
    }
}

