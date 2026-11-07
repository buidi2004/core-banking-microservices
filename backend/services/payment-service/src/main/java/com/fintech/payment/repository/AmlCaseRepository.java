package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.AmlCase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface AmlCaseRepository extends JpaRepository<AmlCase, UUID> {
    List<AmlCase> findAllByOrderByUpdatedAtDesc();
    List<AmlCase> findByStatusOrderByUpdatedAtDesc(String status);
    boolean existsByTransactionIdAndStatusNot(String transactionId, String status);

    @Query("SELECT c FROM AmlCase c WHERE c.slaDueAt < :now AND c.status != :closedStatus")
    List<AmlCase> findAllOverdueBefore(@Param("now") Instant now, @Param("closedStatus") String closedStatus);

    long countByStatusIn(java.util.Collection<String> statuses);
}
