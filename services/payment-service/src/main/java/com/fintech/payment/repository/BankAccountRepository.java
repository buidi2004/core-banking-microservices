package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.BankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BankAccountRepository extends JpaRepository<BankAccount, String> {

    List<BankAccount> findByUserId(String userId);

    Optional<BankAccount> findByIdAndUserId(String id, String userId);

    List<BankAccount> findByUserIdAndDefaultAccountTrue(String userId);
}
