package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Beneficiary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BeneficiaryRepository extends JpaRepository<Beneficiary, String> {

    List<Beneficiary> findByUserId(String userId);
}
