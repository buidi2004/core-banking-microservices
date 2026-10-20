package com.fintech.payment.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryBuyResponse {
    private String ticketCode;
    private String gameName;
    private String drawPeriod;
    private List<Integer> numbers;
    private Long amount;
    private Integer quantity;
    private String status;
    private String message;
}

