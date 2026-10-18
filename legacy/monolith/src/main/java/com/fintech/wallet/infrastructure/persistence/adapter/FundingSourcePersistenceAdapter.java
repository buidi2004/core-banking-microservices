package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.model.FundingSourceStatus;
import com.fintech.wallet.domain.port.out.FundingSourcePersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.FundingSourceEntity;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataFundingSourceRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class FundingSourcePersistenceAdapter implements FundingSourcePersistencePort {

    private final SpringDataFundingSourceRepository repository;

    public FundingSourcePersistenceAdapter(SpringDataFundingSourceRepository repository) {
        this.repository = repository;
    }

    @Override
    public FundingSource save(FundingSource fundingSource) {
        FundingSourceEntity entity = FundingSourceEntity.fromDomain(fundingSource);
        FundingSourceEntity saved = repository.save(entity);
        return saved.toDomain();
    }

    @Override
    public Optional<FundingSource> findById(String id) {
        return repository.findById(id).map(FundingSourceEntity::toDomain);
    }

    @Override
    public List<FundingSource> findByUserIdAndActive(String userId) {
        return repository.findByUserIdAndStatus(userId, FundingSourceStatus.ACTIVE)
                .stream()
                .map(FundingSourceEntity::toDomain)
                .collect(Collectors.toList());
    }
}
