package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.infrastructure.persistence.entity.BeneficiaryJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class BeneficiaryMapper {

    public Beneficiary toDomain(BeneficiaryJpaEntity entity) {
        if (entity == null) return null;
        return new Beneficiary(
                entity.getId(),
                entity.getUserId(),
                entity.getBeneficiaryWalletId(),
                entity.getNickname(),
                entity.getBankCode(),
                entity.getAccountNumber(),
                entity.getCreatedAt()
        );
    }

    public BeneficiaryJpaEntity toJpaEntity(Beneficiary domain) {
        if (domain == null) return null;
        return new BeneficiaryJpaEntity(
                domain.getId(),
                domain.getUserId(),
                domain.getBeneficiaryWalletId(),
                domain.getNickname(),
                domain.getBankCode(),
                domain.getAccountNumber(),
                domain.getCreatedAt()
        );
    }
}
