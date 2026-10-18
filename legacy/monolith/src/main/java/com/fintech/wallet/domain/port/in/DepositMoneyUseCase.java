package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;

public interface DepositMoneyUseCase {
    Transaction deposit(String requestId, String walletId, Money amount);

    default Transaction deposit(String walletId, Money amount) {
        return deposit(null, walletId, amount);
    }
}
