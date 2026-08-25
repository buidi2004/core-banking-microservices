package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.MoneyRequest;
import com.fintech.wallet.domain.port.out.MoneyRequestPersistencePort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Component
public class InMemoryMoneyRequestPersistenceAdapter implements MoneyRequestPersistencePort {

    private final Map<String, MoneyRequest> store = new ConcurrentHashMap<>();

    @Override
    public MoneyRequest saveMoneyRequest(MoneyRequest moneyRequest) {
        store.put(moneyRequest.getId(), moneyRequest);
        return moneyRequest;
    }

    @Override
    public Optional<MoneyRequest> findMoneyRequestById(String requestId) {
        return Optional.ofNullable(store.get(requestId));
    }

    @Override
    public List<MoneyRequest> findMoneyRequestsByPayerId(String payerId) {
        return store.values().stream()
                .filter(req -> payerId != null && payerId.equals(req.getPayerId()))
                .collect(Collectors.toList());
    }

    @Override
    public List<MoneyRequest> findMoneyRequestsByRequesterId(String requesterId) {
        return store.values().stream()
                .filter(req -> requesterId != null && requesterId.equals(req.getRequesterId()))
                .collect(Collectors.toList());
    }
}
