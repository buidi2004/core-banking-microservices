package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Bill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BillRepository extends JpaRepository<Bill, String> {

    Optional<Bill> findByBillId(String billId);

    Optional<Bill> findByCustomerCodeAndStatus(String customerCode, String status);

    List<Bill> findByUserId(String userId);
}

