package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.domain.port.in.BeneficiaryUseCase;
import com.fintech.wallet.presentation.request.AddBeneficiaryRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/beneficiaries")
public class BeneficiaryController {

    private final BeneficiaryUseCase beneficiaryUseCase;

    public BeneficiaryController(BeneficiaryUseCase beneficiaryUseCase) {
        this.beneficiaryUseCase = beneficiaryUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Beneficiary>> addBeneficiary(Authentication auth, @Valid @RequestBody AddBeneficiaryRequest request) {
        String userId = auth.getName();
        Beneficiary beneficiary = beneficiaryUseCase.addBeneficiary(
                userId,
                request.getBeneficiaryWalletId(),
                request.getNickname(),
                request.getBankCode(),
                request.getAccountNumber()
        );
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Beneficiary added successfully", beneficiary));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Beneficiary>>> getBeneficiaries(Authentication auth) {
        String userId = auth.getName();
        List<Beneficiary> beneficiaries = beneficiaryUseCase.getBeneficiaries(userId);
        return ResponseEntity.ok(ApiResponse.success("Beneficiaries retrieved", beneficiaries));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBeneficiary(Authentication auth, @PathVariable String id) {
        String userId = auth.getName();
        beneficiaryUseCase.deleteBeneficiary(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Beneficiary deleted successfully", null));
    }
}
