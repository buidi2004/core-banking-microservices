package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Bank;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BankRepository extends JpaRepository<Bank, String> {

    Optional<Bank> findByCode(String code);

    Optional<Bank> findByBin(String bin);

    List<Bank> findByActiveTrue();
}
