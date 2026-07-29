package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.domain.port.out.BankAccountPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.BankAccountJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.BankAccountMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataBankAccountRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class BankAccountPersistenceAdapter implements BankAccountPersistencePort {

    private final SpringDataBankAccountRepository repository;
    private final BankAccountMapper mapper;

    public BankAccountPersistenceAdapter(SpringDataBankAccountRepository repository, BankAccountMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public BankAccount saveBankAccount(BankAccount bankAccount) {
        BankAccountJpaEntity entity = mapper.toJpaEntity(bankAccount);
        BankAccountJpaEntity saved = repository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public List<BankAccount> findBankAccountsByUserId(String userId) {
        return repository.findByUserId(userId).stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public Optional<BankAccount> findBankAccountById(String bankAccountId) {
        return repository.findById(bankAccountId).map(mapper::toDomain);
    }

    @Override
    public void deleteBankAccount(String bankAccountId) {
        repository.deleteById(bankAccountId);
    }
}
