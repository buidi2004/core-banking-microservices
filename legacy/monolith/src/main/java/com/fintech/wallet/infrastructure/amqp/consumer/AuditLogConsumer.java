package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

@Component
public class AuditLogConsumer {

    private static final Logger log = LoggerFactory.getLogger(AuditLogConsumer.class);

    private final AuditLogPersistencePort auditLogPersistencePort;
    private final WalletPersistencePort walletPersistencePort;
    private final StringRedisTemplate redisTemplate;

    public AuditLogConsumer(AuditLogPersistencePort auditLogPersistencePort, 
                            WalletPersistencePort walletPersistencePort,
                            StringRedisTemplate redisTemplate) {
        this.auditLogPersistencePort = auditLogPersistencePort;
        this.walletPersistencePort = walletPersistencePort;
        this.redisTemplate = redisTemplate;
    }

    @RabbitListener(queues = RabbitMqConfig.QUEUE_AUDIT_LOG)
    public void receiveMessage(TransactionEvent event) {
        String idempotencyKey = "processed:event:auditlog:" + event.getEventId();
        Boolean isNew = redisTemplate.opsForValue().setIfAbsent(idempotencyKey, "1", 24, TimeUnit.HOURS);
        
        if (Boolean.FALSE.equals(isNew)) {
            log.info("Duplicate event ignored in AuditLogConsumer: {}", event.getEventId());
            return;
        }

        log.info("Processing audit log for transaction: {}", event.getTransactionId());
        try {
            String callerId = "system";
            if (event.getSourceWalletId() != null) {
                callerId = walletPersistencePort.findWalletById(event.getSourceWalletId())
                        .map(w -> w.getOwnerId())
                        .orElse(event.getSourceWalletId());
            }

            String action = event.getType();
            String payloadHash = "txId:" + event.getTransactionId() + ",amount:" + event.getAmount();

            AuditLog auditLog = AuditLog.record(callerId, "async-worker", action, payloadHash, event.getEventId());
            try {
                auditLogPersistencePort.saveAuditLog(auditLog);
            } catch (org.springframework.dao.DataIntegrityViolationException dive) {
                log.info("Duplicate event ignored at DB level in AuditLogConsumer: {}", event.getEventId());
            }
            
        } catch (Exception e) {
            log.error("Error processing audit log for transaction {}", event.getTransactionId(), e);
            redisTemplate.delete(idempotencyKey); // Allow retry
            if (e instanceof RuntimeException) {
                throw (RuntimeException) e;
            }
            throw new RuntimeException(e);
        }
    }
}
