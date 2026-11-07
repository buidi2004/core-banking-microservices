package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.DisputeCase;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DisputeCaseRepository extends JpaRepository<DisputeCase, UUID> {
    List<DisputeCase> findAllByOrderByCreatedAtDesc();
    Page<DisputeCase> findAllByOrderByCreatedAtDesc(Pageable pageable);

    List<DisputeCase> findByStatusOrderByCreatedAtDesc(String status);
    Page<DisputeCase> findByStatusOrderByCreatedAtDesc(String status, Pageable pageable);

    List<DisputeCase> findByCustomerIdOrderByCreatedAtDesc(String customerId);
    Page<DisputeCase> findByCustomerIdOrderByCreatedAtDesc(String customerId, Pageable pageable);

    List<DisputeCase> findByTransactionId(String transactionId);

    boolean existsByTransactionIdAndStatusNotIn(String transactionId, Collection<String> statuses);

    long countByStatusIn(Collection<String> statuses);

    Optional<DisputeCase> findFirstByTransactionIdAndStatusNotIn(String transactionId, Collection<String> statuses);
}

