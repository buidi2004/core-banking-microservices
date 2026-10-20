package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.LoanScheduleItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LoanScheduleItemRepository extends JpaRepository<LoanScheduleItem, UUID> {
    List<LoanScheduleItem> findByLoanContractIdOrderByTermNumberAsc(UUID loanContractId);
    Optional<LoanScheduleItem> findByLoanContractIdAndTermNumber(UUID loanContractId, Integer termNumber);
}

