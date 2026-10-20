package com.fintech.payment.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LotteryBuyRequest {

    @NotNull(message = "Tên loại vé không được để trống")
    private String gameName; // Mega 6/45, Power 6/55, Keno

    @NotEmpty(message = "Danh sách số chọn không được rỗng")
    private List<Integer> numbers;

    @Builder.Default
    private Integer quantity = 1;

    private String drawPeriod;

    private String pinToken;
}

