package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "lottery_draws")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryDraw {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "game_name", nullable = false, length = 50)
    private String gameName;

    @Column(name = "draw_period", nullable = false, length = 50)
    private String drawPeriod;

    @Column(name = "draw_date", nullable = false, length = 50)
    private String drawDate;

    @Column(name = "winning_numbers", nullable = false, length = 100)
    private String winningNumbers;

    @Column(name = "special_number")
    private Integer specialNumber;

    @Column(name = "jackpot1_amount", nullable = false)
    private Long jackpot1Amount;

    @Column(name = "jackpot2_amount")
    private Long jackpot2Amount;

    @Column(name = "winners_j1", nullable = false)
    @Builder.Default
    private Integer winnersJ1 = 0;

    @Column(name = "winners_j2", nullable = false)
    @Builder.Default
    private Integer winnersJ2 = 0;

    @Column(name = "created_at")
    @Builder.Default
    private Instant createdAt = Instant.now();
}

