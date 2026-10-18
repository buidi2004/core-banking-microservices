package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.Bank;
import com.fintech.wallet.infrastructure.persistence.entity.BankJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class BankMapper {

    public Bank toDomain(BankJpaEntity entity) {
        if (entity == null) {
            return null;
        }
        return new Bank(
                entity.getId(),
                entity.getBankCode(),
                entity.getBankName(),
                entity.getLogoUrl(),
                entity.isInternal()
        );
    }

    public BankJpaEntity toEntity(Bank domain) {
        if (domain == null) {
            return null;
        }
        return new BankJpaEntity(
                domain.getId(),
                domain.getBankCode(),
                domain.getBankName(),
                domain.getLogoUrl(),
                domain.isInternal()
        );
    }
}
