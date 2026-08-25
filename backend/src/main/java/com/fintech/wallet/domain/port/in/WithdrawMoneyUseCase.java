package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;

public interface WithdrawMoneyUseCase {
    Transaction withdraw(String requestId, String userId, String walletId, String bankAccountId, Money amount);
}
