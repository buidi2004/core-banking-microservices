package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.LoanContract;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LoanContractRepository extends JpaRepository<LoanContract, UUID> {
    List<LoanContract> findByUserIdOrderByCreatedAtDesc(String userId);
    Optional<LoanContract> findByIdAndUserId(UUID id, String userId);
    Optional<LoanContract> findByContractNumber(String contractNumber);
}

