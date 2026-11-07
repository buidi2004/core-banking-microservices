package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.BankAccountDto;
import com.fintech.payment.dto.FundingSourceDto;
import com.fintech.payment.dto.LinkBankAccountRequest;
import com.fintech.payment.service.BankAccountService;
import com.fintech.payment.service.FundingSourceService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/funding-sources")
public class FundingSourceController {

    private final FundingSourceService fundingSourceService;
    private final BankAccountService bankAccountService;

    public FundingSourceController(FundingSourceService fundingSourceService, BankAccountService bankAccountService) {
        this.fundingSourceService = fundingSourceService;
        this.bankAccountService = bankAccountService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<FundingSourceDto>>> getFundingSources(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<FundingSourceDto> sources = fundingSourceService.getFundingSources(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách nguồn tiền thanh toán", sources));
    }

    @PostMapping("/link")
    public ResponseEntity<ApiResponse<BankAccountDto>> linkFundingSource(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @Valid @RequestBody LinkBankAccountRequest request) {
        BankAccountDto account = bankAccountService.linkBankAccount(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Liên kết nguồn tiền ngân hàng thành công", account));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> removeFundingSource(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String id) {
        bankAccountService.unlinkBankAccount(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Hủy liên kết nguồn tiền thành công", null));
    }
}

