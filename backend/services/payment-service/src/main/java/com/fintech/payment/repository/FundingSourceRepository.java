package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.FundingSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FundingSourceRepository extends JpaRepository<FundingSource, String> {

    List<FundingSource> findByUserId(String userId);

    List<FundingSource> findByUserIdAndActiveTrue(String userId);
}
