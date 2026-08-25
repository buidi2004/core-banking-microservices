package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;

/**
 * Output Port: NotificationPort
 * Defines the contract for sending real-time notifications (e.g. WebSocket / Push notification)
 * to client applications when transactions occur.
 */
public interface NotificationPort {
    void notifyTransactionCompleted(Transaction transaction, Wallet wallet);
}
