package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.BeneficiaryJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SpringDataBeneficiaryRepository extends JpaRepository<BeneficiaryJpaEntity, String> {
    List<BeneficiaryJpaEntity> findByUserId(String userId);
}
