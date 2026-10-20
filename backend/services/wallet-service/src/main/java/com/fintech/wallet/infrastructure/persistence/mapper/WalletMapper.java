package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.model.WalletStatus;
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
}

