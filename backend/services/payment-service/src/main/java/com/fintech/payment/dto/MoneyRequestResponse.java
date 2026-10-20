package com.fintech.payment.dto;

import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class MoneyRequestResponse {
    private String id;
    private String requesterId;
    private String targetUserId;
    private Long amount;
    private String status;
    private String note;
}
