package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.BankAccountDto;
import com.fintech.payment.dto.LinkBankAccountRequest;
import com.fintech.payment.service.BankAccountService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/bank-accounts")
public class BankAccountController {

    private final BankAccountService bankAccountService;

    public BankAccountController(BankAccountService bankAccountService) {
        this.bankAccountService = bankAccountService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BankAccountDto>>> getBankAccounts(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<BankAccountDto> accounts = bankAccountService.getUserBankAccounts(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách tài khoản ngân hàng liên kết", accounts));
    }

    @PostMapping("/link")
    public ResponseEntity<ApiResponse<BankAccountDto>> linkBankAccount(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @Valid @RequestBody LinkBankAccountRequest request) {
        BankAccountDto account = bankAccountService.linkBankAccount(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Liên kết tài khoản ngân hàng thành công", account));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> unlinkBankAccount(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String bankAccountId) {
        bankAccountService.unlinkBankAccount(userId, bankAccountId);
        return ResponseEntity.ok(ApiResponse.success("Hủy liên kết tài khoản thành công", null));
    }

    @PatchMapping("/{id}/default")
    public ResponseEntity<ApiResponse<BankAccountDto>> setDefaultBankAccount(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String bankAccountId) {
        BankAccountDto account = bankAccountService.setDefaultBankAccount(userId, bankAccountId);
        return ResponseEntity.ok(ApiResponse.success("Đã đặt làm tài khoản mặc định", account));
    }
}

