package com.fintech.notification.repository;

import com.fintech.notification.entity.Voucher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VoucherRepository extends JpaRepository<Voucher, UUID> {

    Optional<Voucher> findByCodeIgnoreCase(String code);

    List<Voucher> findByActiveTrue();

    long count();
}
