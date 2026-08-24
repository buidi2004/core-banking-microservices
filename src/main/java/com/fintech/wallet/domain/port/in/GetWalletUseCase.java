package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Wallet;

import java.util.Optional;

public interface GetWalletUseCase {
    Wallet getWalletById(String walletId);
    Optional<Wallet> findWalletByOwnerId(String ownerId);
    Wallet createWallet(String ownerId, String currency);

    /**
     * Look up a user's wallet by owner ID and currency.
     * Used in P2P money request flow where we know the userId but not the walletId.
     */
    Wallet getWalletByUserIdAndCurrency(String userId, String currency);

    /**
     * Get masked recipient information for pre-transfer verification.
     */
    com.fintech.wallet.presentation.response.RecipientInfoResponse getRecipientInfo(String walletId, String phoneNumber);
}
