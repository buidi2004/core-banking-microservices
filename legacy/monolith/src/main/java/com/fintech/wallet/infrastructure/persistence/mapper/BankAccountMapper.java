package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.infrastructure.persistence.entity.BankAccountJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class BankAccountMapper {

    public BankAccount toDomain(BankAccountJpaEntity entity) {
        if (entity == null) return null;
        return new BankAccount(
                entity.getId(),
                entity.getUserId(),
                entity.getBankCode(),
                entity.getAccountNumber(),
                entity.getAccountHolderName(),
                entity.isDefault(),
                entity.getCreatedAt()
        );
    }

    public BankAccountJpaEntity toJpaEntity(BankAccount domain) {
        if (domain == null) return null;
        return new BankAccountJpaEntity(
                domain.getId(),
                domain.getUserId(),
                domain.getBankCode(),
                domain.getAccountNumber(),
                domain.getAccountHolderName(),
                domain.isDefault(),
                domain.getCreatedAt()
        );
    }
}
