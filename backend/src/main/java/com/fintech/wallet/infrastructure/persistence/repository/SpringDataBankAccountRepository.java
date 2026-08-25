package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.BankAccountJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SpringDataBankAccountRepository extends JpaRepository<BankAccountJpaEntity, String> {
    List<BankAccountJpaEntity> findByUserId(String userId);
}
