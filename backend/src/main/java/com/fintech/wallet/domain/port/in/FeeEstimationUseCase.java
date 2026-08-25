package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.FeeEstimate;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.TransactionType;

/**
 * Input Port: fee estimation before transaction confirmation.
 * Frontend calls this to display fee breakdown on the confirmation screen.
 */
public interface FeeEstimationUseCase {

    /**
     * Estimate the fee for a transaction before it is executed.
     * @param userId User initiating the transaction (KYC level affects fee)
     * @param type Transaction type (TRANSFER, WITHDRAWAL, etc.)
     * @param amount The principal amount
     * @return FeeEstimate with fee breakdown and total cost
     */
    FeeEstimate estimateFee(String userId, TransactionType type, Money amount);
}
