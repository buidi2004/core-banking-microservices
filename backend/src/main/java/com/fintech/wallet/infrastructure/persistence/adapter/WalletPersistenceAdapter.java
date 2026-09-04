package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.WalletJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.WalletMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataWalletRepository;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * OPT #1: Now only implements WalletPersistencePort (SRP).
 * Transaction persistence has been extracted to TransactionPersistenceAdapter.
 */
@Component
public class WalletPersistenceAdapter implements WalletPersistencePort {

    private final SpringDataWalletRepository walletRepository;
    private final WalletMapper mapper;

    public WalletPersistenceAdapter(SpringDataWalletRepository walletRepository,
                                    WalletMapper mapper) {
        this.walletRepository = walletRepository;
        this.mapper = mapper;
    }

    @Override
    public Wallet saveWallet(Wallet wallet) {
        WalletJpaEntity entity = mapper.toJpaEntity(wallet);
        WalletJpaEntity saved = walletRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<Wallet> findWalletById(String walletId) {
        return walletRepository.findById(walletId).map(mapper::toDomain);
    }

    @Override
    public Optional<Wallet> findWalletByIdForUpdate(String walletId) {
        return walletRepository.findByIdForUpdate(walletId).map(mapper::toDomain);
    }

    @Override
    public Optional<Wallet> findWalletByOwnerId(String ownerId) {
        return walletRepository.findByOwnerId(ownerId).map(mapper::toDomain);
    }

    @Override
    public BigDecimal sumAllBalances() {
        return walletRepository.sumAllBalances();
    }
}
