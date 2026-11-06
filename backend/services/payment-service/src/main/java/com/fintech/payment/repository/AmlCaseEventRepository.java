package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.AmlCaseEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AmlCaseEventRepository extends JpaRepository<AmlCaseEvent, UUID> {
    List<AmlCaseEvent> findByCaseIdOrderByCreatedAtAsc(UUID caseId);
}
