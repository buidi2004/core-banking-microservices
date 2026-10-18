package com.fintech.ledger.it;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.ledger.application.kafka.KafkaEventEnvelope;
import com.fintech.ledger.application.kafka.KafkaTopicConstants;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration;
import org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.SimpleTransactionStatus;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Supplier;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Test Kịch bản 1 (Strict Ordering) & Kịch bản 2 (Idempotent Consumer) của AGENT 4:
 * EmbeddedKafka thật + @KafkaListener thật (group: ledger-posting-group) + sổ cái in-memory
 * mô phỏng chính xác ràng buộc idempotency của ewallet_ledger_db:
 *   - reference_number (eventId) UNIQUE
 *   - 1 giao dịch chỉ có 1 chứng từ POSTED
 *   - Thứ tự ghi sổ = thứ tự partition (Key = walletId / transactionId)
 */
@SpringBootTest(classes = LedgerKafkaScenariosTest.KafkaOnlyTestBoot.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@TestPropertySource(properties = {
        "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.consumer.auto-offset-reset=earliest"
})
@EmbeddedKafka(partitions = 6, topics = {
        KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED,
        KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE
})
class LedgerKafkaScenariosTest {

    @Autowired
    @org.springframework.beans.factory.annotation.Qualifier("itStringKafkaTemplate")
    private KafkaTemplate<String, String> kafkaTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private InMemoryLedgerPersistencePort ledgerPort;

    // -------------------------------------------------------------------------
    // KỊCH BẢN 1: STRICT ORDERING — Nạp tiền → Rút tiền → Nạp tiền, cùng 1 ví
    // Mọi event của ví có cùng Key=walletId → bị tới cùng 1 Partition theo thứ tự offset.
    // Số dư cộng dồn (theo thứ tự ghi sổ) không bao giờ bị âm.
    // -------------------------------------------------------------------------
    @Test
    void scenario1_strictOrdering_preservesBalanceSequenceAndOffsets() throws Exception {
        Thread.sleep(1500); // Đợi consumer partitions ổn định
        String wallet = "wl-order-" + UUID.randomUUID();

        // Nạp tiền → Rút tiền → Nạp tiền (CREDIT = số dư tăng, DEBIT = số dư giảm)
        Map<String, Object> p1 = walletPayload(wallet, "CREDIT", "1000000", "s1-tx-1");
        Map<String, Object> p2 = walletPayload(wallet, "DEBIT", "400000", "s1-tx-2");
        Map<String, Object> p3 = walletPayload(wallet, "CREDIT", "500000", "s1-tx-3");
        sendSequence(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, wallet, "s1-e1", p1);
        sendSequence(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, wallet, "s1-e2", p2);
        sendSequence(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, wallet, "s1-e3", p3);

        // Strict-but-patient: đợi consumer xử lý đủ 3 event cùng partition (thứ tự offset)
        await(() -> ledgerPort.findAllEntries().stream()
                .filter(e -> e.getReferenceNumber() != null
                        && e.getReferenceNumber().startsWith("s1-e"))
                .count() == 3, 20000);

        List<com.fintech.ledger.domain.model.JournalEntry> ordered =
                ledgerPort.findAllEntries().stream()
                        .filter(e -> e.getReferenceNumber() != null
                                && e.getReferenceNumber().startsWith("s1-e"))
                        .toList();
        // Thứ tự offset bảo toàn: e1 → e2 → e3
        assertThat(ordered.stream().map(e -> e.getReferenceNumber()))
                .containsExactly("s1-e1", "s1-e2", "s1-e3");

        String walletAccountId = ledgerPort.walletAccount(wallet).getId();
        // Số dư cộng dồn theo THỨ TỰ GHI SỔ: 1.000.000 → 600.000 → 1.100.000 (luôn ≥ 0)
        List<BigDecimal> timeline = ledgerPort.balanceTimeline(walletAccountId);
        assertThat(timeline).containsExactly(
                new BigDecimal("1000000"),
                new BigDecimal("600000"),
                new BigDecimal("1100000"));
        assertThat(timeline).allSatisfy(b -> assertThat(b.signum()).isGreaterThanOrEqualTo(0));

        // Số dư của Ví khớp số dư cuối: 1.100.000
        assertThat(ledgerPort.balanceTimeline(walletAccountId).get(2))
                .isEqualByComparingTo(new BigDecimal("1100000"));
    }

    // -------------------------------------------------------------------------
    // KỊCH BẢN 2: IDEMPOTENT CONSUMER — event trùng (phát lại) KHÔNG làm DB ghi 2 lần
    // -------------------------------------------------------------------------
    @Test
    void scenario2_idempotentConsumer_duplicateEventsAreRecordedOnceOnly() throws Exception {
        Thread.sleep(1500); // Đợi consumer partitions ổn định
        String sourceWallet = "wl-idem-s-" + UUID.randomUUID();
        String targetWallet = "wl-idem-t-" + UUID.randomUUID();

        // (a) trùng eventId: cùng envelope phát lại 2 lần
        Map<String, Object> p1 = walletPayload(sourceWallet, "CREDIT", "250000", "s2-tx-a");
        send(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, sourceWallet, "s2-e1", p1);
        await(() -> ledgerPort.findAllEntries().stream()
                .anyMatch(e -> "s2-e1".equals(e.getReferenceNumber())), 20000);
        String sourceId = ledgerPort.walletAccount(sourceWallet).getId();
        List<BigDecimal> afterFirst = ledgerPort.balanceTimeline(sourceId);
        assertThat(afterFirst).hasSize(1);
        assertThat(afterFirst.get(0)).isEqualByComparingTo(new BigDecimal("250000"));

        // phát lại CHÍNH XÁC cùng event → không ghi thêm
        send(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, sourceWallet, "s2-e1", p1);
        Thread.sleep(1500);
        assertThat(ledgerPort.findAllEntries().stream()
                .filter(e -> "s2-e1".equals(e.getReferenceNumber())).count()).isEqualTo(1);
        assertThat(ledgerPort.balanceTimeline(sourceId)).hasSize(1); // vẫn 1 posting pair

        // (b) trùng GIAO DỊCH nhưng eventId khác (Saga re-publish lifecycle COMPLETED)
        String txId = "s2-tx-transfer-" + UUID.randomUUID().toString().substring(0, 8);
        Map<String, Object> life = lifecyclePayload(txId, "TRANSFER", "COMPLETED",
                sourceWallet, targetWallet, "100000");
        send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, txId, "s2-e2", life);
        await(() -> ledgerPort.findEntriesByTransactionId(txId).size() == 1, 20000);

        send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, txId, "s2-e2-dup", life);
        Thread.sleep(1500);
        // vẫn duy nhất 1 chứng từ POSTED cho giao dịch (không double-post lần thứ 2)
        assertThat(ledgerPort.findEntriesByTransactionId(txId).size()).isEqualTo(1);
        assertThat(ledgerPort.balanceTimeline(sourceId)).hasSize(2); // 250.000 → 150.000

        // (c) REVERSED thật → bút toán bù (hoàn tiền cho source wallet)
        Map<String, Object> reversal = lifecyclePayload(txId, TRANSFER, "REVERSED",
                sourceWallet, targetWallet, "100000");
        send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, txId, "s2-e3", reversal);
        await(() -> ledgerPort.findEntriesByTransactionId(txId).size() == 2, 20000);

        // REVERSED trùng eventId → không ghi thêm bút toán bù
        send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, txId, "s2-e3", reversal);
        Thread.sleep(1500);
        assertThat(ledgerPort.findEntriesByTransactionId(txId).size()).isEqualTo(2);

        // Số dư cuối ví nguồn: 250.000 → 150.000 → 250.000 (hoàn tiền)
        List<BigDecimal> finalTimeline = ledgerPort.balanceTimeline(sourceId);
        assertThat(finalTimeline).hasSize(3);
        assertThat(finalTimeline.get(2)).isEqualByComparingTo(new BigDecimal("250000"));

        // Toàn sổ: Σ Debit = Σ Credit (bất biến kế toán kép)
        assertThat(ledgerPort.sumAmount(com.fintech.ledger.domain.model.PostingSide.DEBIT))
                .isEqualByComparingTo(ledgerPort.sumAmount(com.fintech.ledger.domain.model.PostingSide.CREDIT));
    }

    // -------------------------------------------------------------------------

    private static final String TRANSFER = "TRANSFER";

    private Map<String, Object> walletPayload(String walletId, String direction, String amount, String txId) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("walletId", walletId);
        payload.put("event", direction);
        payload.put("amount", new BigDecimal(amount));
        payload.put("currency", "VND");
        payload.put("transactionId", txId);
        return payload;
    }

    private Map<String, Object> lifecyclePayload(String txId, String type, String status,
                                                 String source, String target, String amount) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("transactionId", txId);
        payload.put("type", type);
        payload.put("status", status);
        payload.put("sourceWalletId", source);
        payload.put("targetWalletId", target);
        payload.put("amount", new BigDecimal(amount));
        payload.put("currency", "VND");
        return payload;
    }

    private void send(String topic, String key, String eventId, Map<String, Object> payload) throws Exception {
        KafkaEventEnvelope envelope = new KafkaEventEnvelope();
        envelope.setEventId(eventId);
        envelope.setTraceId("trace-" + eventId);
        envelope.setTimestamp(Instant.now().toString());
        envelope.setProducerService("it-test");
        envelope.setTopic(topic);
        envelope.setPayload(payload);
        kafkaTemplate.send(topic, key, objectMapper.writeValueAsString(envelope)).get();
    }

    private void sendSequence(String topic, String walletKey, String eventId, Map<String, Object> payload)
            throws Exception {
        send(topic, walletKey, eventId, payload);
    }

    private void await(Supplier<Boolean> condition, long timeoutMillis) throws InterruptedException {
        long deadline = System.currentTimeMillis() + timeoutMillis;
        while (!condition.get()) {
            if (System.currentTimeMillis() > deadline) {
                throw new AssertionError("Condition not met within " + timeoutMillis + "ms");
            }
            Thread.sleep(100);
        }
    }

    // -------------------------------------------------------------------------
    // Context tối giản: chỉ Kafka + in-memory ledger (không DB, không Rabbit)
    // -------------------------------------------------------------------------
    @SpringBootConfiguration
    @EnableAutoConfiguration(exclude = {
            DataSourceAutoConfiguration.class,
            DataSourceTransactionManagerAutoConfiguration.class,
            HibernateJpaAutoConfiguration.class,
            JpaRepositoriesAutoConfiguration.class,
            FlywayAutoConfiguration.class,
            RabbitAutoConfiguration.class
    })
    @Import(com.fintech.ledger.infrastructure.kafka.KafkaTopicConfig.class)
    static class KafkaOnlyTestBoot {

        @Bean
        InMemoryLedgerPersistencePort ledgerPersistencePort() {
            return new InMemoryLedgerPersistencePort();
        }

        @Bean
        PlatformTransactionManager transactionManager() {
            return new NoopTransactionManager();
        }

        @Bean
        com.fintech.ledger.application.kafka.KafkaLedgerEventTranslator translator() {
            return new com.fintech.ledger.application.kafka.KafkaLedgerEventTranslator();
        }

        @Bean
        com.fintech.ledger.application.service.LedgerService ledgerService(
                InMemoryLedgerPersistencePort port) {
            return new com.fintech.ledger.application.service.LedgerService(port);
        }

        @Bean
        @org.springframework.context.annotation.Primary
        org.springframework.kafka.core.KafkaTemplate<Object, Object> dltKafkaTemplate(
                org.springframework.core.env.Environment env) {
            var cfg = new java.util.HashMap<String, Object>();
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                    env.getProperty("spring.embedded.kafka.brokers"));
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                    org.apache.kafka.common.serialization.StringSerializer.class);
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                    org.springframework.kafka.support.serializer.JsonSerializer.class);
            cfg.put(org.springframework.kafka.support.serializer.JsonSerializer.ADD_TYPE_INFO_HEADERS, false);
            return new org.springframework.kafka.core.KafkaTemplate<>(
                    new org.springframework.kafka.core.DefaultKafkaProducerFactory<>(cfg));
        }

        @Bean("itStringKafkaTemplate")
        org.springframework.kafka.core.KafkaTemplate<String, String> itStringKafkaTemplate(
                org.springframework.core.env.Environment env) {
            var cfg = new java.util.HashMap<String, Object>();
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                    env.getProperty("spring.embedded.kafka.brokers"));
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG,
                    org.apache.kafka.common.serialization.StringSerializer.class);
            cfg.put(org.apache.kafka.clients.producer.ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
                    org.apache.kafka.common.serialization.StringSerializer.class);
            return new org.springframework.kafka.core.KafkaTemplate<>(
                    new org.springframework.kafka.core.DefaultKafkaProducerFactory<>(cfg));
        }

        @Bean
        com.fintech.ledger.infrastructure.kafka.LedgerKafkaConsumer ledgerKafkaConsumer(
                com.fintech.ledger.application.service.LedgerService ledgerService,
                InMemoryLedgerPersistencePort port,
                com.fintech.ledger.application.kafka.KafkaLedgerEventTranslator translator) {
            return new com.fintech.ledger.infrastructure.kafka.LedgerKafkaConsumer(ledgerService, port, translator);
        }
    }

    static final class NoopTransactionManager implements PlatformTransactionManager {
        @Override
        public TransactionStatus getTransaction(TransactionDefinition definition) {
            return new SimpleTransactionStatus();
        }

        @Override
        public void commit(TransactionStatus status) {
        }

        @Override
        public void rollback(TransactionStatus status) {
        }
    }

}
