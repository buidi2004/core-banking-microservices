package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.TransactionEvent;

public interface TransactionEventPublisherPort {
    void publishTransactionEvent(TransactionEvent event);
}
