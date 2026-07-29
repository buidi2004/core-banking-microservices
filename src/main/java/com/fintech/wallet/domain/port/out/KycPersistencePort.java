package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.UserKyc;
import java.util.Optional;

public interface KycPersistencePort {
    UserKyc saveKyc(UserKyc kyc);
    Optional<UserKyc> findKycByUserId(String userId);
}
