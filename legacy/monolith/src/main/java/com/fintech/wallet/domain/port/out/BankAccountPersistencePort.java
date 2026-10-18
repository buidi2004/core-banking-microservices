package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.BankAccount;
import java.util.List;
import java.util.Optional;

public interface BankAccountPersistencePort {
    BankAccount saveBankAccount(BankAccount bankAccount);
    List<BankAccount> findBankAccountsByUserId(String userId);
    Optional<BankAccount> findBankAccountById(String bankAccountId);
    void deleteBankAccount(String bankAccountId);
}
