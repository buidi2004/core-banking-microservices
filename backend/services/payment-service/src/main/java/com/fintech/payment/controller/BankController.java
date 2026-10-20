package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.Bank;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.repository.BankRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/payments/banks")
public class BankController {

    private final BankRepository bankRepository;

    public BankController(BankRepository bankRepository) {
        this.bankRepository = bankRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BankDto>>> listBanks() {
        List<BankDto> banks = bankRepository.findByActiveTrue().stream()
                .map(b -> new BankDto(b.getId(), b.getCode(), b.getName(), b.getShortName(), b.getBin(), b.getLogoUrl(), b.getActive()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Danh sách ngân hàng", banks));
    }

    public record BankDto(String id, String code, String name, String shortName, String bin, String logoUrl, Boolean active) {}
}
