package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;

public interface BillPaymentUseCase {
    Bill queryBill(BillType billType, String customerCode);
    Transaction payBill(String requestId, String userId, String walletId, String billId, Money amount);
    Transaction topupPhone(String requestId, String userId, String walletId, String phoneNumber, Money amount);
}
