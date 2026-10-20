package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.MoneyRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MoneyRequestRepository extends JpaRepository<MoneyRequest, String> {

    List<MoneyRequest> findByRequesterId(String requesterId);

    List<MoneyRequest> findByTargetUserId(String targetUserId);

    List<MoneyRequest> findByStatus(String status);

    Optional<MoneyRequest> findByIdAndRequesterId(String id, String requesterId);

    Optional<MoneyRequest> findByIdAndTargetUserId(String id, String targetUserId);
}
