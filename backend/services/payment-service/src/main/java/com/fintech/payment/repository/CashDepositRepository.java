package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.CashDeposit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CashDepositRepository extends JpaRepository<CashDeposit, String> {

    Optional<CashDeposit> findByDepositCode(String depositCode);

    Optional<CashDeposit> findByIdempotencyKey(String idempotencyKey);

    List<CashDeposit> findByStatus(String status);

    List<CashDeposit> findByMakerId(String makerId);

    List<CashDeposit> findAllByOrderByCreatedAtDesc();

    List<CashDeposit> findByStatusOrderByCreatedAtDesc(String status);

    List<CashDeposit> findByMakerIdOrderByCreatedAtDesc(String makerId);

    List<CashDeposit> findByBranchIdOrderByCreatedAtDesc(String branchId);

    long countByStatus(String status);

    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(SUM(c.amount), 0) FROM CashDeposit c WHERE c.status IN ('COMPLETED', 'APPROVED')")
    long sumCompletedAmount();

    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(SUM(c.amount), 0) FROM CashDeposit c WHERE c.status IN ('COMPLETED', 'APPROVED') AND c.branchId = :branchId")
    long sumCompletedAmountByBranchId(@org.springframework.data.repository.query.Param("branchId") String branchId);
}
