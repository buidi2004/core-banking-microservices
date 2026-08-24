package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.FundingSource;
import java.util.List;
import java.util.Optional;

public interface FundingSourcePersistencePort {
    FundingSource save(FundingSource fundingSource);
    Optional<FundingSource> findById(String id);
    List<FundingSource> findByUserIdAndActive(String userId);
}
