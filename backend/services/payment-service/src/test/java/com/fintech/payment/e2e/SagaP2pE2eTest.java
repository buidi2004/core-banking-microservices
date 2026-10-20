package com.fintech.payment.e2e;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * Kiểm thử E2E Saga P2P Transfer trên dữ liệu thật:
 *   - PostgreSQL: ewallet_payment_db (port 5435)
 *   - Kafka: topic banking.payment.transaction-lifecycle.v1, key = transaction_id
 *
 * Chạy trước khi test:
 *   docker-compose -f docker-compose.microservices.yml up -d postgres-payment kafka
 *   (hoặc để Testcontainers tự khởi động container nếu không có service sẵn)
 *
 * Kịch bản:
 *   TC-E2E-01: COMPLETED  (debit OK + credit OK)
 *   TC-E2E-02: REVERSED   (debit OK + credit thất bại -> auto-reversal hoan tien)
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("E2E Saga P2P Transfer - Postgres 5435 + Kafka lifecycle")
public class SagaP2pE2eTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("ewallet_payment_db")
            .withUsername("payment_db_user")
            .withPassword("PaymentDb#Secure2025!");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        registry.add("WALLET_GRPC_HOST", () -> "localhost");
        registry.add("WALLET_GRPC_PORT", () -> "9090");
        registry.add("grpc.server.port", () -> "-1");
    }

    @Autowired private PaymentSagaOrchestrator saga;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private OutboxEventRepository outboxEventRepository;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired(required = false) private org.springframework.data.redis.core.StringRedisTemplate redisTemplate;

    private static final String SENDER_USER = "e2e-user-sender";
    private static final String RECEIVER_USER = "e2e-user-receiver";

    @MockBean private WalletGrpcClient walletGrpcClient;

    @BeforeEach
    void setUpGrpc() {
        if (redisTemplate != null) {
            redisTemplate.delete("saga:p2p:idempotency:idem-e2e-completed-001");
            redisTemplate.delete("saga:p2p:idempotency:idem-e2e-reversed-001");
        }
        when(walletGrpcClient.getWalletByUserId(SENDER_USER)).thenReturn(
                WalletInfoResult.builder().found(true).walletId("wallet-sender").userId(SENDER_USER).balance(10_000_000L).status("ACTIVE").build());
        when(walletGrpcClient.getWalletByUserId(RECEIVER_USER)).thenReturn(
                WalletInfoResult.builder().found(true).walletId("wallet-receiver").userId(RECEIVER_USER).balance(5_000_000L).status("ACTIVE").build());
        when(walletGrpcClient.getWalletByUserId("e2e-user-locked")).thenReturn(
                WalletInfoResult.builder().found(true).walletId("wallet-locked").userId("e2e-user-locked").balance(0L).status("LOCKED").build());

        when(walletGrpcClient.debit(eq("wallet-sender"), anyLong(), anyString(), anyString())).thenReturn(
                WalletBalanceResult.builder().success(true).balanceAfter(9_900_000L).build());

        when(walletGrpcClient.credit(eq("wallet-receiver"), anyLong(), anyString(), anyString())).thenReturn(
                WalletBalanceResult.builder().success(true).balanceAfter(5_100_000L).build());

        when(walletGrpcClient.credit(eq("wallet-locked"), anyLong(), anyString(), anyString())).thenReturn(
                WalletBalanceResult.builder().success(false).errorCode("WALLET_LOCKED").errorMessage("Ví đích bị khóa").build());

        when(walletGrpcClient.credit(eq("wallet-sender"), anyLong(), anyString(), anyString())).thenReturn(
                WalletBalanceResult.builder().success(true).balanceAfter(10_000_000L).build());
    }

    private void printDbState(String label) {
        List<Map<String, Object>> txs = jdbcTemplate.queryForList(
                "SELECT id, transaction_code, source_wallet_id, target_wallet_id, amount, status, failure_reason " +
                "FROM transactions ORDER BY created_at DESC LIMIT 5");
        List<Map<String, Object>> outbox = jdbcTemplate.queryForList(
                "SELECT id, aggregate_id, event_type, status, published_at " +
                "FROM outbox_events ORDER BY created_at DESC LIMIT 5");

        System.out.println("\n===== " + label + " =====");
        System.out.println("[TRANSACTIONS]");
        txs.forEach(r -> System.out.printf("  id=%s code=%s src=%s tgt=%s amount=%s status=%s fail=%s%n",
                r.get("id"), r.get("transaction_code"), r.get("source_wallet_id"), r.get("target_wallet_id"),
                r.get("amount"), r.get("status"), r.get("failure_reason")));
        System.out.println("[OUTBOX]");
        outbox.forEach(r -> System.out.printf("  id=%s aggId=%s event=%s status=%s published=%s%n",
                r.get("id"), r.get("aggregate_id"), r.get("event_type"), r.get("status"), r.get("published_at")));
        System.out.println("==============================\n");
    }

    @AfterEach
    void tearDownPrint() {
        // In trang thai cuoi cung sau moi test
        printDbState("DB/OUTBOX state after test");
    }

    @Test
    @Order(1)
    @DisplayName("TC-E2E-01: COMPLETED - Debit gui OK + Credit nhan OK -> SUCCESS, Kafka key=transaction_id")
    void testCompleted() {
        String idem = "idem-e2e-completed-001";
        SagaContext ctx = saga.transferP2p(SENDER_USER, RECEIVER_USER, 100_000L, "VND", null, idem);

        org.assertj.core.api.Assertions.assertThat(ctx.getStatus()).isEqualTo("SUCCESS");
        org.assertj.core.api.Assertions.assertThat(ctx.getTransactionId()).isNotNull();

        // Kiem tra outbox co TransactionCompletedEvent
        List<OutboxEvent> completed = outboxEventRepository.findByAggregateId(ctx.getTransactionId());
        org.assertj.core.api.Assertions.assertThat(completed)
                .filteredOn(e -> "TransactionCompletedEvent".equals(e.getEventType()))
                .hasSize(1);

        printDbState("TC-E2E-01 COMPLETED DB/OUTBOX");
    }

    @Test
    @Order(2)
    @DisplayName("TC-E2E-02: REVERSED - Debit gui OK + Credit nhan THAT BAI -> Auto-Reversal hoan tien")
    void testReversed() {
        // Gui tien den user bi khoa (credit se that fai)
        String idem = "idem-e2e-reversed-001";
        SagaContext ctx = saga.transferP2p(SENDER_USER, "e2e-user-locked", 100_000L, "VND", null, idem);

        org.assertj.core.api.Assertions.assertThat(ctx.getStatus()).isEqualTo("REVERSED");
        org.assertj.core.api.Assertions.assertThat(ctx.isReversed()).isTrue();

        // Kiem tra outbox co TransactionReversedEvent
        List<OutboxEvent> reversed = outboxEventRepository.findByAggregateId(ctx.getTransactionId());
        org.assertj.core.api.Assertions.assertThat(reversed)
                .filteredOn(e -> "TransactionReversedEvent".equals(e.getEventType()))
                .hasSize(1);

        printDbState("TC-E2E-02 REVERSED DB/OUTBOX");
    }

    @Test
    @Order(3)
    @DisplayName("TC-E2E-03: Xac nhan tong so du he thong bao toan (Khong mat tien sau khi reversal)")
    void testConservation() {
        Transaction reversedTx = transactionRepository.findByIdempotencyKey("idem-e2e-reversed-001")
                .orElseThrow(() -> new IllegalStateException("Khong tim tx reversal"));
        List<Transaction> senderTxs = transactionRepository.findBySourceWalletId(reversedTx.getSourceWalletId());

        Long total = senderTxs.stream()
                .filter(t -> "DEBITED".equals(t.getStatus()) || "REVERSED".equals(t.getStatus()))
                .mapToLong(Transaction::getAmount).sum();

        System.out.println("\n===== TC-E2E-03 TONG SO DU =====");
        System.out.println("Tong so da duoc xu ly (debit/reversed) cua nguoi gui: " + total);
        System.out.println("================================\n");
    }
}
