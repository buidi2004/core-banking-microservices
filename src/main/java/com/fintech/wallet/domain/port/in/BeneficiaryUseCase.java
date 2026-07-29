package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Beneficiary;
import java.util.List;

public interface BeneficiaryUseCase {
    Beneficiary addBeneficiary(String userId, String beneficiaryWalletId, String nickname, String bankCode, String accountNumber);
    List<Beneficiary> getBeneficiaries(String userId);
    void deleteBeneficiary(String userId, String beneficiaryId);
}
