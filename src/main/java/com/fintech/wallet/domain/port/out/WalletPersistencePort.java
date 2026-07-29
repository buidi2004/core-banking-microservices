package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Wallet;

import java.util.Optional;

public interface WalletPersistencePort {
    Wallet saveWallet(Wallet wallet);
    Optional<Wallet> findWalletById(String walletId);
    Optional<Wallet> findWalletByOwnerId(String ownerId);
}
