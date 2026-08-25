package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.MoneyRequest;

import java.util.List;

/**
 * Use case for P2P money request feature.
 * Allows users to request money from other users (similar to MoMo, ZaloPay).
 */
public interface MoneyRequestUseCase {
    
    /**
     * Create a money request from requester to payer.
     * @param requesterId User who requests money
     * @param payerUserId User who is asked to pay
     * @param amount Amount requested
     * @param message Optional message (e.g., "Lunch money", "Split bill")
     * @return Created MoneyRequest
     */
    MoneyRequest createMoneyRequest(String requesterId, String payerUserId, Money amount, String message);

    /**
     * Accept a money request and execute the transfer.
     * @param requestId Money request ID
     * @param payerUserId User accepting the request (must be the original payer)
     * @return Updated MoneyRequest with transactionId
     */
    MoneyRequest acceptMoneyRequest(String requestId, String payerUserId);

    /**
     * Reject a money request.
     * @param requestId Money request ID
     * @param payerUserId User rejecting the request (must be the original payer)
     * @return Updated MoneyRequest
     */
    MoneyRequest rejectMoneyRequest(String requestId, String payerUserId);

    /**
     * Cancel a money request (only requester can cancel).
     * @param requestId Money request ID
     * @param requesterId User cancelling the request (must be the original requester)
     * @return Updated MoneyRequest
     */
    MoneyRequest cancelMoneyRequest(String requestId, String requesterId);

    /**
     * Get all money requests received by a user (requests where user is the payer).
     * @param userId User ID
     * @return List of money requests
     */
    List<MoneyRequest> getReceivedMoneyRequests(String userId);

    /**
     * Get all money requests sent by a user (requests where user is the requester).
     * @param userId User ID
     * @return List of money requests
     */
    List<MoneyRequest> getSentMoneyRequests(String userId);

    /**
     * Get a specific money request by ID.
     * @param requestId Money request ID
     * @return MoneyRequest
     */
    MoneyRequest getMoneyRequestById(String requestId);
}
