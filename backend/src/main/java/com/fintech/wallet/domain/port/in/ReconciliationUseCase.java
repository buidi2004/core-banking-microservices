package com.fintech.wallet.domain.port.in;

import java.util.Map;

public interface ReconciliationUseCase {
    Map<String, Object> runDailyReconciliation();
}
