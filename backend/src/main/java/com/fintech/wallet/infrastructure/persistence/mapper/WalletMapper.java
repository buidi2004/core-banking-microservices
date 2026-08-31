package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.infrastructure.persistence.entity.TransactionJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.WalletJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class WalletMapper {

    public Wallet toDomain(WalletJpaEntity entity) {
        if (entity == null) return null;
        Money balance = Money.of(entity.getBalanceAmount(), entity.getCurrency());
        return new Wallet(
                entity.getId(),
                entity.getOwnerId(),
                balance,
                entity.getCreatedAt(),
                entity.getUpdatedAt(),
                entity.getVersion()
        );
    }

    public WalletJpaEntity toJpaEntity(Wallet domain) {
        if (domain == null) return null;
        WalletJpaEntity entity = new WalletJpaEntity();
        entity.setId(domain.getId());
        entity.setOwnerId(domain.getOwnerId());
        entity.setBalanceAmount(domain.getBalance().getAmount());
        entity.setCurrency(domain.getBalance().getCurrency());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setUpdatedAt(domain.getUpdatedAt());
        entity.setVersion(domain.getVersion());
        return entity;
    }

    public Transaction toDomain(TransactionJpaEntity entity) {
        if (entity == null) return null;
        Money amount = Money.of(entity.getAmount(), entity.getCurrency());
        return new Transaction(
                entity.getId(),
                entity.getRequestId(),
                entity.getSourceWalletId(),
                entity.getTargetWalletId(),
                amount,
                TransactionType.valueOf(entity.getType()),
                TransactionStatus.valueOf(entity.getStatus()),
                entity.getCreatedAt(),
                null,
                entity.getNote()
        );
    }

    public TransactionJpaEntity toJpaEntity(Transaction domain) {
        if (domain == null) return null;
        return new TransactionJpaEntity(
                domain.getId(),
                domain.getRequestId(),
                domain.getSourceWalletId(),
                domain.getTargetWalletId(),
                domain.getAmount().getAmount(),
                domain.getAmount().getCurrency(),
                domain.getType().name(),
                domain.getStatus().name(),
                domain.getCreatedAt(),
                domain.getNote()
        );
    }
}
