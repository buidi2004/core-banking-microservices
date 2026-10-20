package com.fintech.ledger.infrastructure.amqp;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.domain.model.JournalEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Consumer ghi sổ cái kép Append-Only.
 * - transaction completed (status SUCCESS): ghi chứng từ gốc Nợ/Có balance
 * - transaction reversed (status REVERSED / type REVERSED): ghi chứng từ bù hoàn lại chứng từ gốc
 * Idempotency: reference_number (eventId) UNIQUE + 1 chứng từ POSTED / giao dịch.
 * Lỗi không xử lý được → requeue retry 3 lần → đẩy vào ledger-dlq.
 */
@Component
public class LedgerEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(LedgerEventConsumer.class);

    private final LedgerService ledgerService;

    public LedgerEventConsumer(LedgerService ledgerService) {
        this.ledgerService = ledgerService;
    }

    @RabbitListener(queues = AmqpConfig.LEDGER_QUEUE,
            containerFactory = "ledgerListenerContainerFactory")
    public void onTransactionEvent(TransactionEventMessage event) {
        log.info("Ledger event received: {} (routing transaction.#{})", event);

        String status = event.getStatus() == null ? "" : event.getStatus().toUpperCase();
        switch (status) {
            case "SUCCESS", "COMPLETED", "REVERSED" -> process(event);
            default -> log.info("Event ignored by ledger (not completed/reversed): eventId={}, txId={}, status={}",
                    event.getEventId(), event.getTransactionId(), event.getStatus());
        }
    }

    private void process(TransactionEventMessage event) {
        try {
            JournalEntry recorded = ledgerService.recordTransactionPosting(event);
            if (recorded == null) {
                log.info("Duplicate event ignored at DB level: eventId={}, txId={}",
                        event.getEventId(), event.getTransactionId());
            } else {
                log.info("Journal entry recorded: entryId={}, txId={}, postings ({} rows)",
                        recorded.getId(), event.getTransactionId(), recorded.getPostings().size());
            }
        } catch (IllegalArgumentException e) {
            // Event sai hợp đồng hoặc loại giao dịch không hỗ trợ → giữ để retry rồi xuống DLQ
            log.error("Rejected ledger event (bad contract or unsupported type): eventId={}, txId={}",
                    event.getEventId(), event.getTransactionId(), e);
            throw e;
        }
    }
}
