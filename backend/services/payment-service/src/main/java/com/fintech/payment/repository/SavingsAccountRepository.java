package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.SavingsAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SavingsAccountRepository extends JpaRepository<SavingsAccount, UUID> {
    List<SavingsAccount> findByUserIdOrderByCreatedAtDesc(String userId);
    Optional<SavingsAccount> findByIdAndUserId(UUID id, String userId);
    Optional<SavingsAccount> findByAccountNumber(String accountNumber);
}

