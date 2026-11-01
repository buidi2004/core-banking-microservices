package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Wallet;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface WalletPersistencePort {
    Wallet saveWallet(Wallet wallet);
    Optional<Wallet> findWalletById(String walletId);
    Optional<Wallet> findWalletByIdForUpdate(String walletId);
    Optional<Wallet> findWalletByOwnerId(String ownerId);
    List<Wallet> findAllWallets();
    BigDecimal sumAllBalances();
}
