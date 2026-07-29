package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Wallet;

import java.util.Optional;

public interface GetWalletUseCase {
    Wallet getWalletById(String walletId);
    Optional<Wallet> findWalletByOwnerId(String ownerId);
    Wallet createWallet(String ownerId, String currency);
}
