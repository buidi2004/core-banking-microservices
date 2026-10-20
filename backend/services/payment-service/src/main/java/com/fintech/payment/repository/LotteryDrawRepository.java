package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.LotteryDraw;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LotteryDrawRepository extends JpaRepository<LotteryDraw, String> {
    List<LotteryDraw> findByOrderByCreatedAtDesc();
    Optional<LotteryDraw> findByGameNameAndDrawPeriod(String gameName, String drawPeriod);
}

