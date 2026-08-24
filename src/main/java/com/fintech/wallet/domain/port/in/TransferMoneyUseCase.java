package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;

public interface TransferMoneyUseCase {
    Transaction initTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount);
    
    Transaction confirmTransfer(String transactionId);

    Transaction transfer(String requestId, String sourceWalletId, String targetWalletId, Money amount);

    default Transaction transfer(String sourceWalletId, String targetWalletId, Money amount) {
        return transfer(null, sourceWalletId, targetWalletId, amount);
    }

    default Transaction initTransfer(String sourceWalletId, String targetWalletId, Money amount) {
        return initTransfer(null, sourceWalletId, targetWalletId, amount);
    }
}
