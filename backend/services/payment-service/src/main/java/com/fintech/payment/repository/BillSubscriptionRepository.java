package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.BillSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BillSubscriptionRepository extends JpaRepository<BillSubscription, UUID> {
    List<BillSubscription> findByUserIdOrderByCreatedAtDesc(String userId);
    List<BillSubscription> findByStatusAndAutoDebitDay(String status, Integer autoDebitDay);
    Optional<BillSubscription> findByIdAndUserId(UUID id, String userId);
}

