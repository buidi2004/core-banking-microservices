package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;

public interface TransferMoneyUseCase {
    Transaction initTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount, String note);

    default Transaction initTransfer(String requestId, String sourceWalletId, String targetWalletId, Money amount) {
        return initTransfer(requestId, sourceWalletId, targetWalletId, amount, null);
    }
    
    Transaction confirmTransfer(String transactionId);

    Transaction transfer(String requestId, String sourceWalletId, String targetWalletId, Money amount, String note);

    default Transaction transfer(String requestId, String sourceWalletId, String targetWalletId, Money amount) {
        return transfer(requestId, sourceWalletId, targetWalletId, amount, null);
    }

    default Transaction transfer(String sourceWalletId, String targetWalletId, Money amount) {
        return transfer(null, sourceWalletId, targetWalletId, amount, null);
    }

    default Transaction initTransfer(String sourceWalletId, String targetWalletId, Money amount) {
        return initTransfer(null, sourceWalletId, targetWalletId, amount, null);
    }
}
