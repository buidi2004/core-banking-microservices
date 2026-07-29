package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.out.KycPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.UserKycJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.UserKycMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataUserKycRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class KycPersistenceAdapter implements KycPersistencePort {

    private final SpringDataUserKycRepository kycRepository;
    private final UserKycMapper mapper;

    public KycPersistenceAdapter(SpringDataUserKycRepository kycRepository, UserKycMapper mapper) {
        this.kycRepository = kycRepository;
        this.mapper = mapper;
    }

    @Override
    public UserKyc saveKyc(UserKyc kyc) {
        UserKycJpaEntity entity = mapper.toJpaEntity(kyc);
        UserKycJpaEntity saved = kycRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<UserKyc> findKycByUserId(String userId) {
        return kycRepository.findByUserId(userId).map(mapper::toDomain);
    }
}
