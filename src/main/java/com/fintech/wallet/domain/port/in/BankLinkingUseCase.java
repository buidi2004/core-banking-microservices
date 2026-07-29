package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.BankAccount;
import java.util.List;

public interface BankLinkingUseCase {
    BankAccount linkBankAccount(String userId, String bankCode, String accountNumber, String accountHolderName);
    List<BankAccount> getLinkedAccounts(String userId);
    void unlinkAccount(String userId, String bankAccountId);
}
