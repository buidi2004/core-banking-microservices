package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.TelcoTopup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TelcoTopupRepository extends JpaRepository<TelcoTopup, String> {

    List<TelcoTopup> findByUserId(String userId);
}

