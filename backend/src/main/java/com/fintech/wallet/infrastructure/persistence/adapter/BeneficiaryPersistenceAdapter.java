package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.domain.port.out.BeneficiaryPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.BeneficiaryJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.BeneficiaryMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataBeneficiaryRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class BeneficiaryPersistenceAdapter implements BeneficiaryPersistencePort {

    private final SpringDataBeneficiaryRepository repository;
    private final BeneficiaryMapper mapper;

    public BeneficiaryPersistenceAdapter(SpringDataBeneficiaryRepository repository, BeneficiaryMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public Beneficiary saveBeneficiary(Beneficiary beneficiary) {
        BeneficiaryJpaEntity entity = mapper.toJpaEntity(beneficiary);
        BeneficiaryJpaEntity saved = repository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public List<Beneficiary> findByUserId(String userId) {
        return repository.findByUserId(userId).stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public Optional<Beneficiary> findById(String id) {
        return repository.findById(id).map(mapper::toDomain);
    }

    @Override
    public void deleteById(String id) {
        repository.deleteById(id);
    }
}
