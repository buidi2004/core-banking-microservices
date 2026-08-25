package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.domain.port.in.BeneficiaryUseCase;
import com.fintech.wallet.domain.port.out.BeneficiaryPersistencePort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BeneficiaryService implements BeneficiaryUseCase {

    private final BeneficiaryPersistencePort beneficiaryPersistencePort;

    public BeneficiaryService(BeneficiaryPersistencePort beneficiaryPersistencePort) {
        this.beneficiaryPersistencePort = beneficiaryPersistencePort;
    }

    @Override
    public Beneficiary addBeneficiary(String userId, String beneficiaryWalletId, String nickname, String bankCode, String accountNumber) {
        Beneficiary beneficiary = Beneficiary.createNew(userId, beneficiaryWalletId, nickname, bankCode, accountNumber);
        return beneficiaryPersistencePort.saveBeneficiary(beneficiary);
    }

    @Override
    public List<Beneficiary> getBeneficiaries(String userId) {
        return beneficiaryPersistencePort.findByUserId(userId);
    }

    @Override
    public void deleteBeneficiary(String userId, String beneficiaryId) {
        Beneficiary beneficiary = beneficiaryPersistencePort.findById(beneficiaryId)
                .orElseThrow(() -> new IllegalArgumentException("Beneficiary not found: " + beneficiaryId));
        if (!beneficiary.getUserId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized to delete beneficiary");
        }
        beneficiaryPersistencePort.deleteById(beneficiaryId);
    }
}
