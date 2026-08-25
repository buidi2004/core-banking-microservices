package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;

public interface BillProviderPort {
    Bill fetchBill(BillType billType, String customerCode);
    boolean processBillPayment(String billId, Money amount, String transactionReference);
    boolean processPhoneTopup(String phoneNumber, Money amount, String transactionReference);
}
