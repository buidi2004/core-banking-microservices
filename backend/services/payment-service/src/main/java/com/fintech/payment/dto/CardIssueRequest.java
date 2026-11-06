package com.fintech.payment.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardIssueRequest {
    @NotBlank(message = "Loại thẻ không được để trống (DEBIT, CREDIT, VIRTUAL)")
    @JsonAlias({"cardType", "card_type"})
    private String type;

    private Boolean physical;
    private String deliveryAddress;
}

