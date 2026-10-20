package com.fintech.payment.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryResultDto {
    private String game;
    private String period;
    private String drawDate;
    private String jackpot1;
    private String jackpot2;
    private List<Integer> numbers;
    private Integer special;
    private Integer winnersJ1;
    private Integer winnersJ2;
}

