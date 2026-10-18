package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Bank;
import java.util.List;

public interface GetBankListUseCase {
    List<Bank> getBanks();
}
