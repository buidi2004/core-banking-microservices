package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.FundingSourceDto;
import com.fintech.payment.service.FundingSourceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/funding-sources")
public class FundingSourceController {

    private final FundingSourceService fundingSourceService;

    public FundingSourceController(FundingSourceService fundingSourceService) {
        this.fundingSourceService = fundingSourceService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<FundingSourceDto>>> getFundingSources(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<FundingSourceDto> sources = fundingSourceService.getFundingSources(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách nguồn tiền thanh toán", sources));
    }
}

