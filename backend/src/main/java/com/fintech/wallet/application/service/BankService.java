package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.domain.model.Bank;
import com.fintech.wallet.domain.port.in.BankLinkingUseCase;
import com.fintech.wallet.domain.port.in.GetBankListUseCase;
import com.fintech.wallet.domain.port.out.BankAccountPersistencePort;
import com.fintech.wallet.domain.port.out.BankPersistencePort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class BankService implements BankLinkingUseCase, GetBankListUseCase {

    private final BankAccountPersistencePort bankAccountPersistencePort;
    private final BankPersistencePort bankPersistencePort;

    public BankService(BankAccountPersistencePort bankAccountPersistencePort, BankPersistencePort bankPersistencePort) {
        this.bankAccountPersistencePort = bankAccountPersistencePort;
        this.bankPersistencePort = bankPersistencePort;
    }

    @Override
    @Transactional
    public BankAccount linkBankAccount(String userId, String bankCode, String accountNumber, String accountHolderName) {
        if (bankCode == null || bankCode.isBlank()) throw new IllegalArgumentException("Bank code is required");
        if (accountNumber == null || accountNumber.isBlank()) throw new IllegalArgumentException("Account number is required");
        if (accountHolderName == null || accountHolderName.isBlank()) throw new IllegalArgumentException("Account holder name is required");

        List<BankAccount> existing = bankAccountPersistencePort.findBankAccountsByUserId(userId);
        boolean isDefault = existing.isEmpty(); // First linked account is default

        BankAccount account = BankAccount.createNew(userId, bankCode, accountNumber, accountHolderName, isDefault);
        return bankAccountPersistencePort.saveBankAccount(account);
    }

    @Override
    public List<BankAccount> getLinkedAccounts(String userId) {
        return bankAccountPersistencePort.findBankAccountsByUserId(userId);
    }

    @Override
    @Transactional
    public void unlinkAccount(String userId, String bankAccountId) {
        BankAccount account = bankAccountPersistencePort.findBankAccountById(bankAccountId)
                .orElseThrow(() -> new IllegalArgumentException("Bank account not found: " + bankAccountId));
        if (!account.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized to unlink bank account");
        }
        bankAccountPersistencePort.deleteBankAccount(bankAccountId);
    }

    @Override
    public List<Bank> getBanks() {
        return bankPersistencePort.findAllBanks();
    }
}
