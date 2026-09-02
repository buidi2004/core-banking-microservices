package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.GetBankListUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.BankResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/banks")
public class BankController {

    private final GetBankListUseCase getBankListUseCase;

    public BankController(GetBankListUseCase getBankListUseCase) {
        this.getBankListUseCase = getBankListUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BankResponse>>> getBanks() {
        List<BankResponse> banks = getBankListUseCase.getBanks().stream()
                .map(BankResponse::fromDomain)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Banks retrieved successfully", banks));
    }
}
