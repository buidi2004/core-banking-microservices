package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.MoneyRequest;

import java.util.List;
import java.util.Optional;

/**
 * Output Port: MoneyRequest persistence operations.
 */
public interface MoneyRequestPersistencePort {
    
    MoneyRequest saveMoneyRequest(MoneyRequest moneyRequest);
    
    Optional<MoneyRequest> findMoneyRequestById(String requestId);
    
    List<MoneyRequest> findMoneyRequestsByPayerId(String payerId);
    
    List<MoneyRequest> findMoneyRequestsByRequesterId(String requesterId);
}
