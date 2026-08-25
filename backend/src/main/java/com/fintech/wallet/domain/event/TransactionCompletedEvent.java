package com.fintech.wallet.domain.event;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;

public class TransactionCompletedEvent {

    private final Transaction transaction;
    private final Wallet wallet;

    public TransactionCompletedEvent(Transaction transaction, Wallet wallet) {
        this.transaction = transaction;
        this.wallet = wallet;
    }

    public Transaction getTransaction() { return transaction; }
    public Wallet getWallet() { return wallet; }
}
