package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bank;
import com.fintech.payment.domain.entity.BankAccount;
import com.fintech.payment.dto.BankAccountDto;
import com.fintech.payment.dto.LinkBankAccountRequest;
import com.fintech.payment.repository.BankAccountRepository;
import com.fintech.payment.repository.BankRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
public class BankAccountService {

    private final BankAccountRepository bankAccountRepository;
    private final BankRepository bankRepository;

    public BankAccountService(BankAccountRepository bankAccountRepository, BankRepository bankRepository) {
        this.bankAccountRepository = bankAccountRepository;
        this.bankRepository = bankRepository;
    }

    @Transactional(readOnly = true)
    public List<BankAccountDto> getUserBankAccounts(String userId) {
        List<BankAccount> accounts = bankAccountRepository.findByUserId(userId);
        return accounts.stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional
    public BankAccountDto linkBankAccount(String userId, LinkBankAccountRequest request) {
        Bank bank = bankRepository.findByCode(request.getBankCode())
                .orElseThrow(() -> new IllegalArgumentException("Ngân hàng không tồn tại: " + request.getBankCode()));

        List<BankAccount> existing = bankAccountRepository.findByUserId(userId);
        boolean isDefault = existing.isEmpty() || Boolean.TRUE.equals(request.getIsDefault());

        if (isDefault && !existing.isEmpty()) {
            for (BankAccount ba : existing) {
                if (Boolean.TRUE.equals(ba.getDefaultAccount())) {
                    ba.setDefaultAccount(false);
                    bankAccountRepository.save(ba);
                }
            }
        }

        BankAccount account = BankAccount.builder()
                .userId(userId)
                .bankId(bank.getId())
                .accountNumber(request.getAccountNumber().trim())
                .accountHolderName(request.getAccountHolderName().trim().toUpperCase())
                .verified(true)
                .defaultAccount(isDefault)
                .build();

        account = bankAccountRepository.save(account);
        log.info("Linked bank account {} for user {}", account.getAccountNumber(), userId);
        return toDto(account, bank);
    }

    @Transactional
    public void unlinkBankAccount(String userId, String bankAccountId) {
        BankAccount account = bankAccountRepository.findByIdAndUserId(bankAccountId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Tài khoản ngân hàng không tồn tại: " + bankAccountId));
        bankAccountRepository.delete(account);
        log.info("Unlinked bank account {} for user {}", bankAccountId, userId);
    }

    @Transactional
    public BankAccountDto setDefaultBankAccount(String userId, String bankAccountId) {
        List<BankAccount> accounts = bankAccountRepository.findByUserId(userId);
        BankAccount target = null;
        for (BankAccount ba : accounts) {
            if (ba.getId().equals(bankAccountId)) {
                ba.setDefaultAccount(true);
                target = ba;
            } else {
                ba.setDefaultAccount(false);
            }
            bankAccountRepository.save(ba);
        }
        if (target == null) {
            throw new IllegalArgumentException("Tài khoản ngân hàng không tồn tại: " + bankAccountId);
        }
        return toDto(target);
    }

    private BankAccountDto toDto(BankAccount account) {
        Optional<Bank> bankOpt = bankRepository.findById(account.getBankId());
        return toDto(account, bankOpt.orElse(null));
    }

    private BankAccountDto toDto(BankAccount account, Bank bank) {
        return BankAccountDto.builder()
                .id(account.getId())
                .bankId(account.getBankId())
                .bankCode(bank != null ? bank.getCode() : "UNKNOWN")
                .bankName(bank != null ? bank.getName() : "Ngân hàng liên kết")
                .shortName(bank != null ? bank.getShortName() : "NH")
                .bin(bank != null ? bank.getBin() : "")
                .logoUrl(bank != null ? bank.getLogoUrl() : "")
                .accountNumber(account.getAccountNumber())
                .accountHolderName(account.getAccountHolderName())
                .isVerified(Boolean.TRUE.equals(account.getVerified()))
                .isDefault(Boolean.TRUE.equals(account.getDefaultAccount()))
                .createdAt(account.getCreatedAt())
                .build();
    }
}

