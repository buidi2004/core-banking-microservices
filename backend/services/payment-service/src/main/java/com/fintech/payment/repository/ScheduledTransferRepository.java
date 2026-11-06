package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.ScheduledTransfer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface ScheduledTransferRepository extends JpaRepository<ScheduledTransfer, String> {

    List<ScheduledTransfer> findBySourceUserIdOrderByCreatedAtDesc(String sourceUserId);

    @Query("SELECT s FROM ScheduledTransfer s WHERE s.status = 'ACTIVE' AND s.nextExecutionAt <= :now ORDER BY s.nextExecutionAt ASC")
    List<ScheduledTransfer> findDueTransfers(@Param("now") Instant now);
}

