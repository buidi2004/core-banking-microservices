package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.infrastructure.persistence.entity.UserJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public User toDomain(UserJpaEntity entity) {
        if (entity == null) return null;
        return new User(
                entity.getId(),
                entity.getPhoneNumber(),
                entity.getFullName(),
                entity.getPasswordHash(),
                entity.getPinHash(),
                KycStatus.valueOf(entity.getKycStatus()),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public UserJpaEntity toJpaEntity(User domain) {
        if (domain == null) return null;
        return new UserJpaEntity(
                domain.getId(),
                domain.getPhoneNumber(),
                domain.getFullName(),
                domain.getPasswordHash(),
                domain.getPinHash(),
                domain.getKycStatus().name(),
                domain.getCreatedAt(),
                domain.getUpdatedAt()
        );
    }
}
