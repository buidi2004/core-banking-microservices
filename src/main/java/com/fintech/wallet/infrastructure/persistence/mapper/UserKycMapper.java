package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.infrastructure.persistence.entity.UserKycJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class UserKycMapper {

    public UserKyc toDomain(UserKycJpaEntity entity) {
        if (entity == null) return null;
        return new UserKyc(
                entity.getId(),
                entity.getUserId(),
                entity.getIdCardNumber(),
                entity.getFullName(),
                entity.getDob(),
                entity.getFrontCardUrl(),
                entity.getBackCardUrl(),
                entity.getSelfieUrl(),
                KycStatus.valueOf(entity.getStatus()),
                entity.getCreatedAt(),
                entity.getVerifiedAt()
        );
    }

    public UserKycJpaEntity toJpaEntity(UserKyc domain) {
        if (domain == null) return null;
        return new UserKycJpaEntity(
                domain.getId(),
                domain.getUserId(),
                domain.getIdCardNumber(),
                domain.getFullName(),
                domain.getDob(),
                domain.getFrontCardUrl(),
                domain.getBackCardUrl(),
                domain.getSelfieUrl(),
                domain.getStatus().name(),
                domain.getCreatedAt(),
                domain.getVerifiedAt()
        );
    }
}
