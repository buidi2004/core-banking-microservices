package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.MoneyRequest;
import com.fintech.wallet.domain.port.in.MoneyRequestUseCase;
import com.fintech.wallet.presentation.request.CreateMoneyRequestRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.MoneyRequestResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

/**
 * REST Controller for P2P money request feature.
 * Allows users to request money from friends (similar to MoMo, ZaloPay).
 */
@RestController
@RequestMapping("/api/v1/money-requests")
public class MoneyRequestController {

    private final MoneyRequestUseCase moneyRequestUseCase;

    public MoneyRequestController(MoneyRequestUseCase moneyRequestUseCase) {
        this.moneyRequestUseCase = moneyRequestUseCase;
    }

    /**
     * Create a new money request.
     * POST /api/v1/money-requests
     */
    @PostMapping
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> createMoneyRequest(
            Authentication auth, @Valid @RequestBody CreateMoneyRequestRequest request) {
        String requesterId = auth.getName();
        Money amount = Money.of(request.getAmount(), request.getCurrency());
        MoneyRequest moneyRequest = moneyRequestUseCase.createMoneyRequest(
                requesterId, request.getPayerUserId(), amount, request.getMessage());
        MoneyRequestResponse response = MoneyRequestResponse.fromDomain(moneyRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Money request created successfully", response));
    }

    /**
     * Accept a money request (payer accepts and the transfer is executed).
     * POST /api/v1/money-requests/{id}/accept
     */
    @PostMapping("/{id}/accept")
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> acceptMoneyRequest(
            Authentication auth, @PathVariable String id) {
        String payerUserId = auth.getName();
        MoneyRequest moneyRequest = moneyRequestUseCase.acceptMoneyRequest(id, payerUserId);
        MoneyRequestResponse response = MoneyRequestResponse.fromDomain(moneyRequest);
        return ResponseEntity.ok(ApiResponse.success("Money request accepted and transfer completed", response));
    }

    /**
     * Reject a money request (payer declines).
     * POST /api/v1/money-requests/{id}/reject
     */
    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> rejectMoneyRequest(
            Authentication auth, @PathVariable String id) {
        String payerUserId = auth.getName();
        MoneyRequest moneyRequest = moneyRequestUseCase.rejectMoneyRequest(id, payerUserId);
        MoneyRequestResponse response = MoneyRequestResponse.fromDomain(moneyRequest);
        return ResponseEntity.ok(ApiResponse.success("Money request rejected", response));
    }

    /**
     * Cancel a money request (only the requester can cancel).
     * POST /api/v1/money-requests/{id}/cancel
     */
    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> cancelMoneyRequest(
            Authentication auth, @PathVariable String id) {
        String requesterId = auth.getName();
        MoneyRequest moneyRequest = moneyRequestUseCase.cancelMoneyRequest(id, requesterId);
        MoneyRequestResponse response = MoneyRequestResponse.fromDomain(moneyRequest);
        return ResponseEntity.ok(ApiResponse.success("Money request cancelled", response));
    }

    /**
     * Get money requests received by the current user (where user is the payer).
     * GET /api/v1/money-requests/received
     */
    @GetMapping("/received")
    public ResponseEntity<ApiResponse<List<MoneyRequestResponse>>> getReceivedMoneyRequests(Authentication auth) {
        String userId = auth.getName();
        List<MoneyRequest> requests = moneyRequestUseCase.getReceivedMoneyRequests(userId);
        List<MoneyRequestResponse> response = requests.stream()
                .map(MoneyRequestResponse::fromDomain)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Received money requests retrieved", response));
    }

    /**
     * Get money requests sent by the current user (where user is the requester).
     * GET /api/v1/money-requests/sent
     */
    @GetMapping("/sent")
    public ResponseEntity<ApiResponse<List<MoneyRequestResponse>>> getSentMoneyRequests(Authentication auth) {
        String userId = auth.getName();
        List<MoneyRequest> requests = moneyRequestUseCase.getSentMoneyRequests(userId);
        List<MoneyRequestResponse> response = requests.stream()
                .map(MoneyRequestResponse::fromDomain)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Sent money requests retrieved", response));
    }

    /**
     * Get a specific money request by ID.
     * GET /api/v1/money-requests/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> getMoneyRequestById(@PathVariable String id) {
        MoneyRequest moneyRequest = moneyRequestUseCase.getMoneyRequestById(id);
        MoneyRequestResponse response = MoneyRequestResponse.fromDomain(moneyRequest);
        return ResponseEntity.ok(ApiResponse.success("Money request retrieved", response));
    }
}
