package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "lottery_tickets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryTicket {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    @Column(name = "ticket_code", nullable = false, unique = true, length = 50)
    private String ticketCode;

    @Column(name = "game_name", nullable = false, length = 50)
    private String gameName;

    @Column(name = "draw_period", nullable = false, length = 50)
    private String drawPeriod;

    @Column(name = "selected_numbers", nullable = false, length = 100)
    private String selectedNumbers;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 1;

    @Column(nullable = false, length = 50)
    @Builder.Default
    private String status = "PENDING_DRAW";

    @Column(name = "winning_amount", nullable = false)
    @Builder.Default
    private Long winningAmount = 0L;

    @Column(name = "created_at")
    @Builder.Default
    private Instant createdAt = Instant.now();
}

