package com.fintech.wallet.infrastructure.config;

import com.fintech.wallet.application.service.WalletService;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SpringBeanConfig {

    @Bean
    public WalletService walletService(WalletPersistencePort walletPersistencePort,
                                       TransactionPersistencePort transactionPersistencePort,
                                       DistributedLockPort distributedLockPort,
                                       NotificationPort notificationPort,
                                       TransactionalOperationPort transactionalOperationPort,
                                       BankGatewayPort bankGatewayPort,
                                       UserPersistencePort userPersistencePort,
                                       AuditLogPersistencePort auditLogPersistencePort) {
        return new WalletService(walletPersistencePort, transactionPersistencePort,
                distributedLockPort, notificationPort, transactionalOperationPort, bankGatewayPort,
                userPersistencePort, auditLogPersistencePort);
    }
}


