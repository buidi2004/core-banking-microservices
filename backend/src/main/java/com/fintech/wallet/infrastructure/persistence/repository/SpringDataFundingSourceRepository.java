package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.domain.model.FundingSourceStatus;
import com.fintech.wallet.infrastructure.persistence.entity.FundingSourceEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataFundingSourceRepository extends JpaRepository<FundingSourceEntity, String> {
    List<FundingSourceEntity> findByUserIdAndStatus(String userId, FundingSourceStatus status);
}
