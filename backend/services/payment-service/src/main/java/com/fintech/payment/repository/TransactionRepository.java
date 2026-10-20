package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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

    /**
     * Lịch sử biến động số dư của một ví (nguồn hoặc đích).
     * type rỗng = tất cả; TRANSFER_OUT/TRANSFER_IN lọc theo vai trò của ví trong giao dịch.
     * B-02 & B-03: Nếu status = 'REVERSED', ví đích không có credit thực nên loại trừ;
     * ví nguồn được hoàn tiền nên hiển thị dưới dạng TRANSFER_IN.
     */
    @Query(value = "SELECT t FROM Transaction t "
            + "WHERE (t.sourceWalletId = :walletId OR (t.targetWalletId = :walletId AND t.status != 'REVERSED')) "
            + "AND (:type = '' "
            + "     OR (:type = 'TRANSFER_OUT' AND t.sourceWalletId = :walletId AND t.status != 'REVERSED') "
            + "     OR (:type = 'TRANSFER_IN' AND ((t.targetWalletId = :walletId AND t.status != 'REVERSED') "
            + "                                    OR (t.sourceWalletId = :walletId AND t.status = 'REVERSED'))) "
            + "     OR t.type = :type) "
            + "ORDER BY t.createdAt DESC",
            countQuery = "SELECT count(t) FROM Transaction t "
            + "WHERE (t.sourceWalletId = :walletId OR (t.targetWalletId = :walletId AND t.status != 'REVERSED')) "
            + "AND (:type = '' "
            + "     OR (:type = 'TRANSFER_OUT' AND t.sourceWalletId = :walletId AND t.status != 'REVERSED') "
            + "     OR (:type = 'TRANSFER_IN' AND ((t.targetWalletId = :walletId AND t.status != 'REVERSED') "
            + "                                    OR (t.sourceWalletId = :walletId AND t.status = 'REVERSED'))) "
            + "     OR t.type = :type)")
    Page<Transaction> findWalletHistory(@Param("walletId") String walletId,
                                        @Param("type") String type,
                                        Pageable pageable);
}
