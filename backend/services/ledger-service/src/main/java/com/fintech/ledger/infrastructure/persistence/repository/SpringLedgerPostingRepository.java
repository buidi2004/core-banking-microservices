package com.fintech.ledger.infrastructure.persistence.repository;

import com.fintech.ledger.infrastructure.persistence.entity.LedgerPostingJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Repository
public interface SpringLedgerPostingRepository extends JpaRepository<LedgerPostingJpaEntity, UUID> {

    List<LedgerPostingJpaEntity> findByJournalEntryIdOrderByCreatedAtAsc(UUID journalEntryId);

    List<LedgerPostingJpaEntity> findByAccountIdOrderByCreatedAtAsc(UUID accountId);

    List<LedgerPostingJpaEntity> findByAccountIdOrderByCreatedAtDesc(UUID accountId);

    @Query("""
            SELECT p FROM LedgerPostingJpaEntity p
            WHERE p.accountId = :accountId
              AND p.createdAt >= :from AND p.createdAt < :toExclusive
            ORDER BY p.createdAt ASC
            """)
    List<LedgerPostingJpaEntity> findByAccountIdBetween(@Param("accountId") UUID accountId,
                                                        @Param("from") java.time.LocalDateTime from,
                                                        @Param("toExclusive") java.time.LocalDateTime toExclusive);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM LedgerPostingJpaEntity p WHERE p.side = :side")
    BigDecimal sumAmountBySide(@Param("side") String side);

    @Query("""
            SELECT COALESCE(SUM(p.amount), 0) FROM LedgerPostingJpaEntity p
            WHERE p.accountId = :accountId AND p.side = :side
            """)
    BigDecimal sumAmountByAccountIdAndSide(@Param("accountId") UUID accountId, @Param("side") String side);
}
