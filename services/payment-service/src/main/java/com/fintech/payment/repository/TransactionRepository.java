package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, String> {

    Optional<Transaction> findByTransactionCode(String transactionCode);

    Optional<Transaction> findByIdempotencyKey(String idempotencyKey);

    List<Transaction> findBySourceWalletId(String sourceWalletId);

    List<Transaction> findByTargetWalletId(String targetWalletId);

    List<Transaction> findByStatus(String status);

    @Query("SELECT t FROM Transaction t WHERE t.idempotencyKey = :idempotencyKey")
    Optional<Transaction> findByIdempotencyKeyNamed(@Param("idempotencyKey") String idempotencyKey);
}
