package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.Card;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CardRepository extends JpaRepository<Card, String> {

    List<Card> findByUserId(String userId);

    Optional<Card> findByIdAndUserId(String id, String userId);

    Optional<Card> findByCardNumber(String cardNumber);
}

