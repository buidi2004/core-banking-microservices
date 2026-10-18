package com.fintech.wallet.domain.model;

import java.math.BigDecimal;

public class Bill {
    private final String billId;
    private final BillType billType;
    private final String customerCode;
    private final String providerCode;
    private final String customerName;
    private final BigDecimal amount;
    private final String period;
    private final boolean paid;

    public Bill(String billId, BillType billType, String customerCode, String providerCode, String customerName, BigDecimal amount, String period, boolean paid) {
        this.billId = billId;
        this.billType = billType;
        this.customerCode = customerCode;
        this.providerCode = providerCode;
        this.customerName = customerName;
        this.amount = amount;
        this.period = period;
        this.paid = paid;
    }

    public String getBillId() { return billId; }
    public BillType getBillType() { return billType; }
    public String getCustomerCode() { return customerCode; }
    public String getProviderCode() { return providerCode; }
    public String getCustomerName() { return customerName; }
    public BigDecimal getAmount() { return amount; }
    public String getPeriod() { return period; }
    public boolean isPaid() { return paid; }
}
