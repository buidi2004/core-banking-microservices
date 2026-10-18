package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.AuditLog;

public interface AuditLogPersistencePort {
    void saveAuditLog(AuditLog auditLog);
}
