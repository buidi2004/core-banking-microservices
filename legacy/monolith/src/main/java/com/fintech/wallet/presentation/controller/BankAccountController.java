package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.domain.port.in.BankLinkingUseCase;
import com.fintech.wallet.presentation.request.LinkBankRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.BankAccountResponse;
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
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/bank-accounts")
public class BankAccountController {

    private final BankLinkingUseCase bankLinkingUseCase;

    public BankAccountController(BankLinkingUseCase bankLinkingUseCase) {
        this.bankLinkingUseCase = bankLinkingUseCase;
    }

    @PostMapping("/link")
    public ResponseEntity<ApiResponse<BankAccountResponse>> linkAccount(Authentication auth, @Valid @RequestBody LinkBankRequest request) {
        String userId = auth.getName();
        BankAccount account = bankLinkingUseCase.linkBankAccount(
                userId,
                request.getBankCode(),
                request.getAccountNumber(),
                request.getAccountHolderName()
        );
        BankAccountResponse response = BankAccountResponse.fromDomain(account);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Bank account linked successfully", response));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BankAccountResponse>>> getLinkedAccounts(Authentication auth) {
        String userId = auth.getName();
        List<BankAccount> accounts = bankLinkingUseCase.getLinkedAccounts(userId);
        List<BankAccountResponse> response = accounts.stream()
                .map(BankAccountResponse::fromDomain)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Linked bank accounts retrieved", response));
    }

    @DeleteMapping("/{bankAccountId}")
    public ResponseEntity<ApiResponse<Void>> unlinkAccount(Authentication auth, @PathVariable String bankAccountId) {
        String userId = auth.getName();
        bankLinkingUseCase.unlinkAccount(userId, bankAccountId);
        return ResponseEntity.ok(ApiResponse.success("Bank account unlinked successfully", null));
    }
}
