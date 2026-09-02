package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Bank;
import java.util.List;

public interface BankPersistencePort {
    List<Bank> findAllBanks();
}
