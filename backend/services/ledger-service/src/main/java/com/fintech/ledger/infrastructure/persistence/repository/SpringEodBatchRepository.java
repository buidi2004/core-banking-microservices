package com.fintech.ledger.infrastructure.persistence.repository;

import com.fintech.ledger.infrastructure.persistence.entity.EodBatchJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SpringEodBatchRepository extends JpaRepository<EodBatchJpaEntity, UUID> {

    Optional<EodBatchJpaEntity> findByBatchId(String batchId);

    List<EodBatchJpaEntity> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
