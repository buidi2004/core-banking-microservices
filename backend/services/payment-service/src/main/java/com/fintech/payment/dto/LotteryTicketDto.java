package com.fintech.payment.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryTicketDto {
    private String code;
    private String game;
    private String drawDate;
    private String drawPeriod;
    private List<Integer> numbers;
    private Integer specialNum;
    private Long amount;
    private Integer quantity;
    private String status;
    private boolean canCheck;
}

