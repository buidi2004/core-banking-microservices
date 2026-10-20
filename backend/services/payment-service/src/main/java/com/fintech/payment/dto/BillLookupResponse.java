package com.fintech.payment.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BillLookupResponse {
    private String billId;
    private String serviceType;
    private String providerCode;
    private String providerName;
    private String customerCode;
    private String customerName;
    private String customerAddress;
    private String period;
    private BigDecimal amount;
    private BigDecimal fee;
    private LocalDate dueDate;
    private String status;
}

