package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.MoneyRequest;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.MoneyRequestUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.port.out.MoneyRequestPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Application Service: MoneyRequestService
 * Implements P2P money request feature where users can request money from other users.
 */
@Service
public class MoneyRequestService implements MoneyRequestUseCase {

    private static final Logger log = LoggerFactory.getLogger(MoneyRequestService.class);

    private final MoneyRequestPersistencePort moneyRequestPersistencePort;
    private final GetWalletUseCase getWalletUseCase;
    private final TransferMoneyUseCase transferMoneyUseCase;

    public MoneyRequestService(MoneyRequestPersistencePort moneyRequestPersistencePort,
                              GetWalletUseCase getWalletUseCase,
                              TransferMoneyUseCase transferMoneyUseCase) {
        this.moneyRequestPersistencePort = moneyRequestPersistencePort;
        this.getWalletUseCase = getWalletUseCase;
        this.transferMoneyUseCase = transferMoneyUseCase;
    }

    @Override
    @Transactional
    public MoneyRequest createMoneyRequest(String requesterId, String payerUserId, Money amount, String message) {
        if (requesterId == null || requesterId.isBlank()) {
            throw new IllegalArgumentException("Requester ID cannot be null or empty");
        }
        if (payerUserId == null || payerUserId.isBlank()) {
            throw new IllegalArgumentException("Payer user ID cannot be null or empty");
        }
        if (requesterId.equals(payerUserId)) {
            throw new IllegalArgumentException("Cannot request money from yourself");
        }
        if (amount == null) {
            throw new IllegalArgumentException("Amount cannot be null");
        }

        // Get wallets for both users (will throw if wallets don't exist)
        Wallet requesterWallet = getWalletUseCase.getWalletByUserIdAndCurrency(requesterId, amount.getCurrency());
        Wallet payerWallet = getWalletUseCase.getWalletByUserIdAndCurrency(payerUserId, amount.getCurrency());

        // Validate currency match
        if (!requesterWallet.getBalance().getCurrency().equalsIgnoreCase(payerWallet.getBalance().getCurrency())) {
            throw new IllegalArgumentException("Currency mismatch between requester and payer wallets");
        }

        MoneyRequest request = MoneyRequest.create(
            requesterId,
            payerUserId,
            requesterWallet.getId(),
            payerWallet.getId(),
            amount,
            message
        );

        MoneyRequest savedRequest = moneyRequestPersistencePort.saveMoneyRequest(request);
        log.info("Money request created: id={}, requester={}, payer={}, amount={}", 
                 savedRequest.getId(), requesterId, payerUserId, amount);
        
        return savedRequest;
    }

    @Override
    @Transactional
    public MoneyRequest acceptMoneyRequest(String requestId, String payerUserId) {
        if (requestId == null || requestId.isBlank()) {
            throw new IllegalArgumentException("Request ID cannot be null or empty");
        }
        if (payerUserId == null || payerUserId.isBlank()) {
            throw new IllegalArgumentException("Payer user ID cannot be null or empty");
        }

        MoneyRequest request = moneyRequestPersistencePort.findMoneyRequestById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Money request not found: " + requestId));

        // Verify the user accepting is the payer
        if (!request.getPayerId().equals(payerUserId)) {
            throw new IllegalArgumentException("Only the payer can accept this money request");
        }

        if (!request.canBeAcceptedOrRejected()) {
            throw new IllegalStateException("Money request cannot be accepted. Current status: " + request.getStatus());
        }

        // Execute the transfer from payer to requester
        Transaction transaction = transferMoneyUseCase.transfer(
            request.getPayerWalletId(),
            request.getRequesterWalletId(),
            request.getAmount()
        );

        // Update request status
        request.accept(transaction.getId());
        MoneyRequest updatedRequest = moneyRequestPersistencePort.saveMoneyRequest(request);
        
        log.info("Money request accepted: id={}, transactionId={}", requestId, transaction.getId());
        return updatedRequest;
    }

    @Override
    @Transactional
    public MoneyRequest rejectMoneyRequest(String requestId, String payerUserId) {
        if (requestId == null || requestId.isBlank()) {
            throw new IllegalArgumentException("Request ID cannot be null or empty");
        }
        if (payerUserId == null || payerUserId.isBlank()) {
            throw new IllegalArgumentException("Payer user ID cannot be null or empty");
        }

        MoneyRequest request = moneyRequestPersistencePort.findMoneyRequestById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Money request not found: " + requestId));

        // Verify the user rejecting is the payer
        if (!request.getPayerId().equals(payerUserId)) {
            throw new IllegalArgumentException("Only the payer can reject this money request");
        }

        if (!request.canBeAcceptedOrRejected()) {
            throw new IllegalStateException("Money request cannot be rejected. Current status: " + request.getStatus());
        }

        request.reject();
        MoneyRequest updatedRequest = moneyRequestPersistencePort.saveMoneyRequest(request);
        
        log.info("Money request rejected: id={}", requestId);
        return updatedRequest;
    }

    @Override
    @Transactional
    public MoneyRequest cancelMoneyRequest(String requestId, String requesterId) {
        if (requestId == null || requestId.isBlank()) {
            throw new IllegalArgumentException("Request ID cannot be null or empty");
        }
        if (requesterId == null || requesterId.isBlank()) {
            throw new IllegalArgumentException("Requester ID cannot be null or empty");
        }

        MoneyRequest request = moneyRequestPersistencePort.findMoneyRequestById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Money request not found: " + requestId));

        // Verify the user cancelling is the requester
        if (!request.getRequesterId().equals(requesterId)) {
            throw new IllegalArgumentException("Only the requester can cancel this money request");
        }

        if (!request.canBeCancelled()) {
            throw new IllegalStateException("Money request cannot be cancelled. Current status: " + request.getStatus());
        }

        request.cancel();
        MoneyRequest updatedRequest = moneyRequestPersistencePort.saveMoneyRequest(request);
        
        log.info("Money request cancelled: id={}", requestId);
        return updatedRequest;
    }

    @Override
    public List<MoneyRequest> getReceivedMoneyRequests(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("User ID cannot be null or empty");
        }
        return moneyRequestPersistencePort.findMoneyRequestsByPayerId(userId);
    }

    @Override
    public List<MoneyRequest> getSentMoneyRequests(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("User ID cannot be null or empty");
        }
        return moneyRequestPersistencePort.findMoneyRequestsByRequesterId(userId);
    }

    @Override
    public MoneyRequest getMoneyRequestById(String requestId) {
        if (requestId == null || requestId.isBlank()) {
            throw new IllegalArgumentException("Request ID cannot be null or empty");
        }
        return moneyRequestPersistencePort.findMoneyRequestById(requestId)
            .orElseThrow(() -> new IllegalArgumentException("Money request not found: " + requestId));
    }
}
