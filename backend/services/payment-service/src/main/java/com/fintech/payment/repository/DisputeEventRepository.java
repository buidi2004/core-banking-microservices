package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.DisputeEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DisputeEventRepository extends JpaRepository<DisputeEvent, UUID> {
    List<DisputeEvent> findByDisputeIdOrderByCreatedAtAsc(UUID disputeId);
}

