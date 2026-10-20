package com.fintech.ledger.infrastructure.kafka;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.kafka.KafkaEventEnvelope;
import com.fintech.ledger.application.kafka.KafkaLedgerEventTranslator;
import com.fintech.ledger.application.port.LedgerPersistencePort;
import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.domain.model.JournalEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

/**
 * Idempotent Kafka Consumer của ledger-posting-group:
 * - Lắng nghe 2 topic: wallet balance-changed + payment transaction-lifecycle.
 * - Idempotency 2 lớp trước khi hạch toán:
 *     (1) reference_number (eventId) UNIQUE — event phát lại chỉ ghi 1 lần;
 *     (2) giao dịch đã có chứng từ POSTED → không ghi thêm (COMPLETED phát lại với eventId khác).
 * - Hạch toán 1 Nợ (DEBIT) - 1 Có (CREDIT), bất biến Debit = Credit (JournalEntry chặn).
 * - MANUAL_IMMEDIATE ack CHỈ sau khi hạch toán DB thành công → Zero Data Loss.
 * - Lỗi tiếp diễn → DefaultErrorHandler (retry 3) rồi đẩy topic + ".DLT".
 */
@Component
public class LedgerKafkaConsumer {

    private static final Logger log = LoggerFactory.getLogger(LedgerKafkaConsumer.class);

    private final LedgerService ledgerService;
    private final LedgerPersistencePort persistencePort;
    private final KafkaLedgerEventTranslator translator;

    public LedgerKafkaConsumer(LedgerService ledgerService,
                               LedgerPersistencePort persistencePort,
                               KafkaLedgerEventTranslator translator) {
        this.ledgerService = ledgerService;
        this.persistencePort = persistencePort;
        this.translator = translator;
    }

    /** Topic biến động số dư ví (Agent 2). Event phản ánh số dư thực tế → hạch toán mọi CREDIT/DEBIT. */
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_WALLET_BALANCE_CHANGED,
            containerFactory = "ledgerKafkaListenerContainerFactory")
    public void onWalletBalanceChanged(@Payload KafkaEventEnvelope envelope,
                                       @Header(name = "kafka_receivedMessageKey", required = false) String messageKey,
                                       Acknowledgment acknowledgment) {
        log.info("Kafka wallet.balance-changed received: key={}, {}", messageKey, envelope);
        TransactionEventMessage event = translator.fromWalletBalanceChanged(envelope);
        // Balance-changed event luôn là kết quả thực tế → luôn hạch toán (direction CREDIT/DEBIT)
        postAndAck(envelope, event, acknowledgment);
    }

    /** Topic vòng đời giao dịch Saga (Agent 3) + Quầy nạp tiền mặt (Cash Deposit): chỉ hạch toán COMPLETED / SUCCESS / REVERSED. */
    @KafkaListener(topics = {KafkaTopicConfig.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, KafkaTopicConfig.TOPIC_CASH_DEPOSIT_COMPLETED},
            containerFactory = "ledgerKafkaListenerContainerFactory")
    public void onPaymentLifecycle(@Payload KafkaEventEnvelope envelope,
                                   @Header(name = "kafka_receivedMessageKey", required = false) String messageKey,
                                   Acknowledgment acknowledgment) {
        log.info("Kafka payment.transaction-lifecycle received: key={}, {}", messageKey, envelope);
        TransactionEventMessage event;
        try {
            event = translator.fromPaymentLifecycle(envelope, messageKey);
        } catch (IllegalArgumentException e) {
            log.warn("Malformed payment lifecycle event (skipping): key={}, error={}", messageKey, e.getMessage());
            acknowledgment.acknowledge();
            return;
        }
        String status = event.getStatus() == null ? "" : event.getStatus().toUpperCase();
        if (!status.equals("SUCCESS") && !status.equals("COMPLETED") && !status.equals("REVERSED")) {
            log.info("Saga state ignored by ledger (not completed/reversed): eventId={}, txId={}, status={}",
                    envelope.getEventId(), event.getTransactionId(), event.getStatus());
            acknowledgment.acknowledge();
            return;
        }
        // Cùng 1 giao dịch có thể đến từ cả Rabbit và Kafka với eventId khác nhau:
        // nếu chứng từ gốc đã POSTED thì bỏ qua (tránh rollback/DLQ).
        if (!"REVERSED".equals(status)
                && event.getTransactionId() != null
                && persistencePort.findPostedEntryByTransactionId(event.getTransactionId()).isPresent()) {
            log.info("Transaction already posted, skipping Kafka duplicate: txId={}", event.getTransactionId());
            acknowledgment.acknowledge();
            return;
        }
        postAndAck(envelope, event, acknowledgment);
    }

    private void postAndAck(KafkaEventEnvelope envelope, TransactionEventMessage event, Acknowledgment acknowledgment) {
        try {
            // (1) bộ lọc idempotency theo eventId trước khi hạch toán
            String refId = event.getEventId() != null ? event.getEventId() : envelope.getEventId();
            if (refId != null && persistencePort.existsJournalEntryByReference(refId)) {
                log.info("Duplicate event ignored (idempotent consumer): eventId={}, txId={}",
                        refId, event.getTransactionId());
                acknowledgment.acknowledge();
                return;
            }
            JournalEntry recorded = ledgerService.recordTransactionPosting(event);
            if (recorded == null) {
                log.info("Event already posted previously (idempotent consumer): eventId={}, txId={}",
                        envelope.getEventId(), event.getTransactionId());
            } else {
                log.info("Journal entry recorded from Kafka: entryId={}, txId={}, side DEBIT/CREDIT balance, {} lines",
                        recorded.getId(), event.getTransactionId(), recorded.getPostings().size());
            }
            // (2) ack ngay sau khi hạch toán DB thành công
            acknowledgment.acknowledge();
        } catch (IllegalArgumentException e) {
            log.warn("Malformed transaction event for ledger posting (skipping): eventId={}, txId={}, error={}",
                    envelope.getEventId(), event.getTransactionId(), e.getMessage());
            acknowledgment.acknowledge();
        } catch (DataIntegrityViolationException e) {
            // Xảy ra khi Rabbit và Kafka xử lý song song cùng giao dịch: unique index
            // uq_journal_entries_transaction_posted đã chặn bút toán trùng.
            log.warn("Duplicate journal posting ignored (already posted): eventId={}, txId={}",
                    envelope.getEventId(), event.getTransactionId());
            acknowledgment.acknowledge();
        } catch (RuntimeException e) {
            log.error("Kafka ledger posting failed (will retry / DLT): eventId={}, txId={}",
                    envelope.getEventId(), event.getTransactionId(), e);
            // KHÔNG ack — offset giữ nguyên để retry/DLT theo DefaultErrorHandler
            throw e;
        }
    }
}
