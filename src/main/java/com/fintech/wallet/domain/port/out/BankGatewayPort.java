package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Money;

public interface BankGatewayPort {
    boolean transferToBank(String bankAccountId, Money amount, String transactionReference);
}
