package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.CashInTransitOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CashInTransitRepository extends JpaRepository<CashInTransitOrder, UUID> {
    List<CashInTransitOrder> findAllByOrderByCreatedAtDesc();
    List<CashInTransitOrder> findByStatusOrderByCreatedAtDesc(String status);
    Optional<CashInTransitOrder> findByOrderCode(String orderCode);
    long countByStatusIn(java.util.Collection<String> statuses);
}

