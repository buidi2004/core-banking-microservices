package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.Bank;
import com.fintech.wallet.domain.port.out.BankPersistencePort;
import com.fintech.wallet.infrastructure.persistence.mapper.BankMapper;
import com.fintech.wallet.infrastructure.persistence.repository.BankRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class BankPersistenceAdapter implements BankPersistencePort {

    private final BankRepository bankRepository;
    private final BankMapper bankMapper;

    public BankPersistenceAdapter(BankRepository bankRepository, BankMapper bankMapper) {
        this.bankRepository = bankRepository;
        this.bankMapper = bankMapper;
    }

    @Override
    public List<Bank> findAllBanks() {
        return bankRepository.findAll().stream()
                .map(bankMapper::toDomain)
                .collect(Collectors.toList());
    }
}
