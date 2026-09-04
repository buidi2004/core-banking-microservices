package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.in.GenerateReceiptUseCase;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.TimeUnit;

@Component
public class ReceiptGenerationConsumer {

    private static final Logger log = LoggerFactory.getLogger(ReceiptGenerationConsumer.class);

    private final GenerateReceiptUseCase generateReceiptUseCase;
    private final WalletPersistencePort walletPersistencePort;
    private final StringRedisTemplate redisTemplate;

    public ReceiptGenerationConsumer(GenerateReceiptUseCase generateReceiptUseCase,
                                     WalletPersistencePort walletPersistencePort,
                                     StringRedisTemplate redisTemplate) {
        this.generateReceiptUseCase = generateReceiptUseCase;
        this.walletPersistencePort = walletPersistencePort;
        this.redisTemplate = redisTemplate;
    }

    @RabbitListener(queues = RabbitMqConfig.QUEUE_RECEIPT)
    public void receiveMessage(TransactionEvent event) {
        String idempotencyKey = "processed:event:receipt:" + event.getEventId();
        Boolean isNew = redisTemplate.opsForValue().setIfAbsent(idempotencyKey, "1", 24, TimeUnit.HOURS);
        
        if (Boolean.FALSE.equals(isNew)) {
            log.info("Duplicate event ignored in ReceiptGenerationConsumer: {}", event.getEventId());
            return;
        }

        log.info("Processing receipt generation for transaction: {}", event.getTransactionId());
        try {
            String userId = "system";
            if (event.getSourceWalletId() != null) {
                userId = walletPersistencePort.findWalletById(event.getSourceWalletId())
                        .map(w -> w.getOwnerId())
                        .orElse("system");
            }

            // Sinh PDF (tái sử dụng OpenPDF logic)
            byte[] pdfBytes = generateReceiptUseCase.generateReceiptPdf(event.getTransactionId(), userId);
            
            // Mock S3 Upload
            String s3Bucket = "s3://ewallet-receipts-prod/";
            String objectKey = "receipt_" + event.getTransactionId() + ".pdf";
            log.info("Mocking S3 upload of {} bytes to {}{}", pdfBytes.length, s3Bucket, objectKey);
            
            log.info("Successfully generated and uploaded receipt to S3");
            
        } catch (Exception e) {
            log.error("Error processing receipt generation for transaction {}", event.getTransactionId(), e);
            redisTemplate.delete(idempotencyKey); // Allow retry
            if (e instanceof RuntimeException) {
                throw (RuntimeException) e;
            }
            throw new RuntimeException(e);
        }
    }
}
