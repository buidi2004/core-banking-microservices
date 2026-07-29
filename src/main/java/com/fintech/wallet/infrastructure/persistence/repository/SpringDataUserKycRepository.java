package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.UserKycJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface SpringDataUserKycRepository extends JpaRepository<UserKycJpaEntity, String> {
    Optional<UserKycJpaEntity> findByUserId(String userId);
}
