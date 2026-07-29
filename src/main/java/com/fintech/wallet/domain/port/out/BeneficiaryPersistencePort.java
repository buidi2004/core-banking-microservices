package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Beneficiary;
import java.util.List;
import java.util.Optional;

public interface BeneficiaryPersistencePort {
    Beneficiary saveBeneficiary(Beneficiary beneficiary);
    List<Beneficiary> findByUserId(String userId);
    Optional<Beneficiary> findById(String id);
    void deleteById(String id);
}
