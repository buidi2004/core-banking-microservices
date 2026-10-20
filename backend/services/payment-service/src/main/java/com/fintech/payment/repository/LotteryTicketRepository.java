package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.LotteryTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LotteryTicketRepository extends JpaRepository<LotteryTicket, String> {
    List<LotteryTicket> findByUserIdOrderByCreatedAtDesc(String userId);
    List<LotteryTicket> findByDrawPeriodAndStatus(String drawPeriod, String status);
    Optional<LotteryTicket> findByTicketCode(String ticketCode);
}

