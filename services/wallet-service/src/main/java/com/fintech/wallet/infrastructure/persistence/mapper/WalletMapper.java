package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.model.WalletStatus;
import com.fintech.wallet.infrastructure.persistence.entity.TransactionJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.WalletJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class WalletMapper {

    public Wallet toDomain(WalletJpaEntity entity) {
        if (entity == null) return null;
        Money balance = Money.of(entity.getBalance(), entity.getCurrency());
        WalletStatus status = entity.getStatus() != null ? WalletStatus.valueOf(entity.getStatus()) : WalletStatus.ACTIVE;
        return new Wallet(
                entity.getId(),
                entity.getOwnerId(),
                balance,
                entity.getReservedBalance(),
                entity.getCreatedAt(),
                entity.getUpdatedAt(),
                entity.getVersion(),
                status,
                entity.getDailyLimit(),
                entity.getDailySpent()
        );
    }

    public WalletJpaEntity toJpaEntity(Wallet domain) {
        if (domain == null) return null;
        WalletJpaEntity entity = new WalletJpaEntity();
        entity.setId(domain.getId());
        entity.setOwnerId(domain.getOwnerId());
        entity.setBalance(domain.getBalance().getAmount());
        entity.setReservedBalance(domain.getReservedBalance() != null ? domain.getReservedBalance() : java.math.BigDecimal.ZERO);
        entity.setCurrency(domain.getBalance().getCurrency());
        entity.setStatus(domain.getStatus() != null ? domain.getStatus().name() : WalletStatus.ACTIVE.name());
        entity.setDailyLimit(domain.getDailyLimit());
        entity.setDailySpent(domain.getDailySpent());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setUpdatedAt(domain.getUpdatedAt());
        entity.setVersion(domain.getVersion());
        return entity;
    }

    public Transaction toDomain(TransactionJpaEntity entity) {
        if (entity == null) return null;
        Money amount = Money.of(entity.getAmount(), entity.getCurrency());
        Transaction tx = new Transaction(
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
        tx.setBankCode(entity.getBankCode());
        if (entity.getFeeAmount() != null) {
            tx.setFeeAmount(Money.of(entity.getFeeAmount(), entity.getCurrency()));
        }
        if (entity.getBalanceAfter() != null) {
            tx.setBalanceAfter(Money.of(entity.getBalanceAfter(), entity.getCurrency()));
        }
        if (entity.getReceiverBalanceAfter() != null) {
            tx.setReceiverBalanceAfter(Money.of(entity.getReceiverBalanceAfter(), entity.getCurrency()));
        }
        return tx;
    }

    public TransactionJpaEntity toJpaEntity(Transaction domain) {
        if (domain == null) return null;
        TransactionJpaEntity jpaEntity = new TransactionJpaEntity(
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
        jpaEntity.setBankCode(domain.getBankCode());
        if (domain.getFeeAmount() != null) {
            jpaEntity.setFeeAmount(domain.getFeeAmount().getAmount());
        }
        if (domain.getBalanceAfter() != null) {
            jpaEntity.setBalanceAfter(domain.getBalanceAfter().getAmount());
        }
        if (domain.getReceiverBalanceAfter() != null) {
            jpaEntity.setReceiverBalanceAfter(domain.getReceiverBalanceAfter().getAmount());
        }
        return jpaEntity;
    }
}
