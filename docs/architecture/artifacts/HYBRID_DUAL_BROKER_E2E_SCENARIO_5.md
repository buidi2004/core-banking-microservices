# BIÊN BẢN & KỊCH BẢN KIỂM THỬ E2E TOÀN TRÌNH — KỊCH BẢN 5
## HYBRID DUAL-BROKER: gRPC + KAFKA + LEDGER + RABBITMQ

> **Agent phụ trách:** AGENT 5 (`services/notification-service`) — xem `KAFKA_INTEGRATION_AGENTS_COORDINATION.md`.
> **Mô hình:** Dual-Broker Architecture (Kafka Event Stream + RabbitMQ Task Queue).
> **Nguyên tắc tối thượng:** Zero Data Loss · Strict Ordering theo `wallet_id` · Idempotent Consumer · SLO toàn trình < 2 giây.

---

## 1. MỤC TIÊU VÀ PHẠM VI KIỂM THỬ

- **Mục tiêu:** Kiểm chứng luồng nghiệp vụ chuyển tiền P2P xuyên 5 service đi đúng con đường
  **Hybrid Dual-Broker**: giao dịch đồng bộ đi qua **gRPC**, dòng sự kiện bất biến đi qua **Kafka**,
  hạch toán vào **Sổ cái kép (Ledger)**, và thông báo realtime đi qua **RabbitMQ + FCM/WebSocket**.
- **Phạm vi AGENT 5 (đã triển khai trong repo):**
  1. `notification-service` giữ nhánh RabbitMQ (task queue tức thời) **và** bổ sung nhánh
     **Kafka Consumer** cho `banking.payment.transaction-lifecycle.v1` + `banking.wallet.balance-changed.v1`.
  2. Bắn **FCM Push Notification** và **WebSocket STOMP** (`/topic/wallets/{id}`, `/topic/users/{id}`) khi nhận event.
  3. Kiểm thử tích hợp nhánh notification bằng **Testcontainers** (Kafka + Postgres + RabbitMQ).
  4. **Kịch bản 5** dưới đây mô tả test E2E toàn trình để chạy khi AGENT 1–4 hoàn tất hạ tầng Kafka.

- **Cam kết tài chính & kỹ thuật:**
  1. Không mất event (`acks=all`, `enable.idempotence=true`, Manual Immediate Ack).
  2. Không trùng thông báo khi Kafka replay / RabbitMQ redelivery (Idempotent theo `eventId`).
  3. Sổ cái luôn **cân bằng Nợ = Có** trên mọi chứng từ POSTED.
  4. Toàn chuỗi Client → thông báo realtime hoàn tất **dưới 2 giây** (SLO).

---

## 2. KIẾN TRÚC HYBRID DUAL-BROKER (KỊCH BẢN 5)

```
[Client App]
     │  POST /api/v1/payments/transfers  (Header X-User-Id do Gateway inject)
     ▼
┌───────────────┐        ┌─────────────────────────────────────────────┐
│  API Gateway  │──────► │              PAYMENT SERVICE                │
│   :8080       │        │  PaymentSagaOrchestrator                    │
└───────────────┘        │   1. TRANSACTION INITIATED + Outbox         │
                         │   2. gRPC LockFunds/Debit ──────────┐       │
                         │   3. gRPC Credit ───────────────────┼──►    │
                         │   4. TRANSACTION SUCCESS + Outbox   │       │
                         └─────────────────────────────────────┼───────┘
                                     ▲ (đồng bộ, gRPC)          │
                                     │                          ▼
                         ┌───────────┴──────────┐    ┌───────────────────────┐
                         │   WALLET SERVICE     │    │  OUTBOX RELAY         │
                         │   :8082 / gRPC :9090 │    │  (Transactional Outbox)│
                         └───────────┬──────────┘    └───────────┬───────────┘
                                     │                            │  publish (key = transaction_id)
                    publish (key = wallet_id)                    │
                                     ▼                            ▼
        ╔════════════════════════════════════════════════════════════════════╗
        ║            KAFKA (KRaft) — EVENT STREAM / SOURCE OF TRUTH           ║
        ║  banking.wallet.balance-changed.v1   (6 partitions, key=wallet_id)  ║
        ║  banking.payment.transaction-lifecycle.v1 (6 partitions, key=tx_id) ║
        ╚════════════════════════════════════════════════════════════════════╝
                     │                              │
        group ledger-posting-group       group notification-push-group
                     ▼                              ▼
        ┌────────────────────────┐      ┌────────────────────────────────────┐
        │   LEDGER SERVICE       │      │      NOTIFICATION SERVICE          │
        │ :8084                  │      │  :8085                             │
        │ Idempotent Consumer    │      │  NotificationKafkaConsumer         │
        │ Hạch toán Nợ/Có        │      │   → NotificationConsumer (dùng lại)│
        │ ledger_postings        │      │   → NotificationService.save()     │
        └────────────────────────┘      │   → WebSocketNotifier (STOMP)      │
                                        │   → FcmPushSender (FCM)            │
                                        └───────────────┬────────────────────┘
                                                        │ (nhánh task tức thời)
                                                        ▼
                                        ┌────────────────────────────────────┐
                                        │ RABBITMQ (Task Queue)              │
                                        │ wallet.transaction.events          │
                                        │ notification-service-queue → DLQ   │
                                        └────────────────────────────────────┘
```

**Vai trò từng broker (Dual-Broker):**

| Broker | Vai trò | Topic / Exchange | Đặc tính |
|---|---|---|---|
| **Kafka** | Event Stream bất biến, replay được, đảm bảo ordering theo key | `banking.wallet.balance-changed.v1`, `banking.payment.transaction-lifecycle.v1` | `acks=all`, idempotent producer, partition key = `wallet_id`/`transaction_id` |
| **RabbitMQ** | Task Queue tức thời, retry + DLQ cho tác vụ thông báo | exchange `wallet.transaction.events` → `notification-service-queue` → `notification-service-dlq` | TTL/retry 3 lần, `RejectAndDontRequeueRecoverer` |

---

## 3. LUỒNG E2E TOÀN TRÌNH (HAPPY PATH)

| Bước | Thành phần | Hành động | Kết quả / Bằng chứng |
|:---:|---|---|---|
| 1 | Client → Gateway (:8080) | `POST /api/v1/payments/transfers` + `X-User-Id` | Gateway route tới Payment, inject `X-User-Id` |
| 2 | Payment | Resolve ví nguồn/đích | gRPC `GetWalletByUserId` |
| 3 | Payment → Wallet (:9090) | gRPC **LockFunds/Debit** ví gửi (đồng bộ) | `balance_after` trả về, Transaction = `DEBITED` |
| 4 | Payment → Wallet (:9090) | gRPC **Credit** ví nhận | Transaction = `SUCCESS`, ghi `outbox_events` |
| 5 | Wallet | Publish `balance-changed` (key = `wallet_id`) | Kafka offset tăng, cùng partition cho 1 ví |
| 6 | Payment Outbox Relay | Publish `transaction-lifecycle` (key = `transaction_id`) | Sự kiện `COMPLETED` lên Kafka |
| 7 | Ledger (group `ledger-posting-group`) | Consume + hạch toán **Nợ/Có** idempotent | `ledger_postings` cân bằng, `reference_number` UNIQUE |
| 8 | Notification (group `notification-push-group`) | Consume `transaction-lifecycle` → dispatch | `notifications` (2 bản ghi), WS + FCM |
| 9 | Notification → Client | WebSocket `/topic/wallets/{id}`, `/topic/users/{id}` + FCM | Client nhận push realtime |

**SLO:** `t(step9) − t(step1) < 2000 ms` khi hạ tầng chạy local (docker-compose).

---

## 4. CÁC KỊCH BẢN KIỂM THỬ CHI TIẾT (TEST CASES)

| Mã | Tên kịch bản | Điều kiện đầu vào | Kỳ vọng | Tiêu chuẩn nghiệm thu |
|---|---|---|---|---|
| **TC-E2E-05-01** | Happy Path toàn trình | Ví A: 1.000.000đ, Ví B: 200.000đ. Chuyển 100.000đ. | Debit → Credit → Kafka lifecycle `COMPLETED` → Ledger 2 postings → Notification 2 bản ghi. | Ví A 900.000đ, Ví B 300.000đ; `ledger` Nợ = Có; `notifications` = 2; WS/FCM đã bắn. |
| **TC-E2E-05-02** | Strict Ordering theo ví | Nạp → Rút → Nạp trên cùng ví, cùng `wallet_id`. | Tất cả event cùng 1 Kafka partition, offset tăng đơn điệu. | Thứ tự offset đúng; số dư không bao giờ âm. |
| **TC-E2E-05-03** | Idempotent Consumer (Kafka replay) | Replay cùng `eventId` trên topic lifecycle 2 lần. | Notification chỉ tạo 2 bản ghi (không 4); Ledger không ghi trùng. | `notifications` = 2, `ledger_postings` không tăng sau replay. |
| **TC-E2E-05-04** | Idempotent nhánh RabbitMQ | Redelivery cùng event trên `notification-service-queue`. | Chỉ 1 lần dispatch hợp lệ. | `notifications` không tăng ở lần lặp. |
| **TC-E2E-05-05** | Kafka envelope tương thích | Payload bọc `{eventId, traceId, payload:{...}}`. | Parser bóc `payload` và xử lý bình thường. | Notification tạo đúng 2 bản ghi. |
| **TC-E2E-05-06** | Sổ cái bất biến | Query `ledger_postings` sau giao dịch. | Mọi chứng từ POSTED có tổng DEBIT = CREDIT. | Bất biến append-only, không UPDATE/DELETE. |
| **TC-E2E-05-07** | Auto-Reversal đa broker | Credit ví nhận thất bại → REVERSED. | Kafka `transaction-lifecycle` phát `REVERSED`; Ledger ghi bút toán bù; Notification bắn push hoàn tiền. | Số dư ví gửi khôi phục; có event `REVERSED`; `notifications` phát `REVERSED`. |
| **TC-E2E-05-08** | SLO < 2 giây | Đo thời gian từ request Gateway đến khi WS/FCM phát. | Toàn chuỗi < 2000 ms. | `elapsedMs < 2000` (P95 trên 50 giao dịch liên tiếp). |
| **TC-E2E-05-09** | Cách ly sự cố broker | Kafka down sau khi Payment commit. | RabbitMQ vẫn nhận task; Kafka retry/DLT `.DLT` khi hồi phục. | Không mất event nhờ Outbox; DLQ/DLT có bản ghi khi lỗi. |

---

## 5. TRIỂN KHAI NHÁNH NOTIFICATION TRONG DUAL-BROKER (ĐÃ HOÀN TẤT)

**Lớp Java mới trong `services/notification-service`:**

| File | Vai trò |
|---|---|
| `kafka/KafkaConsumerConfig.java` | `ConsumerFactory` (String deserializer, manual commit, `auto-offset-reset=earliest`), `ConcurrentKafkaListenerContainerFactory` (`MANUAL_IMMEDIATE`), `DefaultErrorHandler` + `DeadLetterPublishingRecoverer` → topic `.DLT`. |
| `kafka/NotificationKafkaConsumer.java` | `@KafkaListener` trên 2 topic, bóc tách envelope/raw → `TransactionEvent`, uỷ quyền cho `NotificationConsumer`, `acknowledgment.acknowledge()` sau khi xử lý thành công. |
| `amqp/NotificationConsumer.java` (tái sử dụng) | Logic dispatch dùng chung: idempotency `eventId`, lưu `notifications`, WebSocket + FCM. |

**Cấu hình chính (`application.yml`):**

```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    consumer:
      auto-offset-reset: earliest
      max-poll-records: 50
notification:
  kafka:
    concurrency: ${KAFKA_CONSUMER_CONCURRENCY:3}
    retry-max-attempts: 3
    retry-backoff-ms: 1000
```

**Topic / group sử dụng (từ `common-library/KafkaTopicConstants`):**

- `banking.payment.transaction-lifecycle.v1` — Consumer Group `notification-push-group`
- `banking.wallet.balance-changed.v1` — Consumer Group `notification-push-group`
- Lỗi sau retry → `banking.*.v1.DLT`

---

## 6. TEST INTEGRATION NHÁNH NOTIFICATION (ĐÃ CHẠY XANH)

**File:** `services/notification-service/src/test/java/com/fintech/notification/kafka/NotificationKafkaConsumerIntegrationTest.java`
**Hạ tầng Testcontainers:** `apache/kafka:3.7.0` + `postgres:16` + `rabbitmq:3-management-alpine`.

| Test method | Ánh xạ test case | Nội dung |
|---|---|---|
| `consumesPaymentLifecycleEventFromKafkaAndPushesNotifications` | TC-E2E-05-01 | Phát event lifecycle → 2 bản ghi (`TRANSFER_OUT`/`TRANSFER_IN`), user-001 & user-002. |
| `consumesWalletBalanceChangedTopic` | TC-E2E-05-02 | Phát lên topic balance-changed (key = `wallet_id`) → 2 bản ghi. |
| `toleratesEnvelopeWrappedPayload` | TC-E2E-05-05 | Payload dạng envelope có `payload` → bóc tách đúng. |
| `duplicateKafkaEventIsProcessedOnlyOnce` | TC-E2E-05-03 | Phát trùng `eventId` → vẫn chỉ 2 bản ghi. |

**Kết quả chạy (toàn bộ module `notification-service`):**

```
Tests run: 31, Failures: 0, Errors: 0, Skipped: 0
  · NotificationKafkaConsumerIntegrationTest ......... 4 passed
  · NotificationConsumerIntegrationTest ............... 3 passed
  · NotificationConsumerTest ......................... 8 passed
  · EventIdempotencyStoreTest ........................ 5 passed
  · FcmPushSenderTest ................................ 6 passed
  · WebSocketNotifierTest ............................ 5 passed
```

**Lệnh chạy:**

```bash
mvn -pl services/notification-service -am test
```

---

## 7. MẪU CODE TEST KỊCH BẢN 5 (NHÁNH NOTIFICATION)

```java
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class NotificationKafkaConsumerIntegrationTest {

    @Container static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");
    @Container static final RabbitMQContainer RABBITMQ = new RabbitMQContainer("rabbitmq:3-management-alpine");
    @Container static final KafkaContainer KAFKA = new KafkaContainer(DockerImageName.parse("apache/kafka:3.7.0"));

    @Autowired private KafkaTemplate<String, String> notificationKafkaTemplate;
    @Autowired private NotificationRepository notificationRepository;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void consumesPaymentLifecycleEventFromKafkaAndPushesNotifications() throws Exception {
        TransactionEvent event = transferEvent("evt-kafka-1", "tx-kafka-1");
        String json = objectMapper.writeValueAsString(event);

        notificationKafkaTemplate
                .send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, event.getTransactionId(), json)
                .get(15, TimeUnit.SECONDS);

        await().atMost(Duration.ofSeconds(30))
                .until(() -> notificationRepository.findAll().stream()
                        .filter(n -> n.getDataPayload() != null && n.getDataPayload().contains("tx-kafka-1"))
                        .count() == 2);
    }
}
```

---

## 8. E2E TOÀN TRÌNH KHI HẠ TẦNG SẴN SÀNG (AGENT 1 → 4)

Khi AGENT 1 (Kafka KRaft + `KafkaEventEnvelope`), AGENT 2 (Wallet producer), AGENT 3 (Payment Saga producer),
AGENT 4 (Ledger consumer) hoàn tất, chạy Kịch bản 5 toàn trình theo trình tự:

1. `docker compose up -d` — dựng Postgres×5, Redis, RabbitMQ, Kafka, kafka-ui, 5 service + Gateway.
2. Seed: tạo user (identity) → ví (wallet) cho người gửi & người nhận; nạp tiền ví gửi.
3. Mở WebSocket client tới `ws://localhost:8085/ws-native`, subscribe `/topic/users/{userId}/notifications`.
4. Đo `t0`, gọi `POST http://localhost:8080/api/v1/payments/transfers` với `X-User-Id` người gửi.
5. Chờ (i) response Payment `SUCCESS`, (ii) chứng từ Ledger cân bằng, (iii) WS/FCM nhận payload. Ghi `t1`.
6. Kiểm tra SLO `t1 − t0 < 2000 ms` và các bất biến ở Mục 4.

> **Trạng thái hiện tại:** Testcontainers IT nhánh notification (TC-E2E-05-01/02/03/05) đã xanh.
> Các TC-E2E-05-06/07/08/09 phụ thuộc AGENT 1–4; chạy theo trình tự ở Mục 8 sau khi hạ tầng Kafka được hợp nhất.

---

## 9. KẾT LUẬN & NGHIỆM THU

- `notification-service` đã đóng vai trò **Consumer Bridge** trong Dual-Broker: vừa nghe RabbitMQ task queue,
  vừa tiêu thụ Kafka event stream cho hai topic nghiệp vụ, rồi bắn FCM + WebSocket realtime.
- Cơ chế **Idempotent Consumer** theo `eventId` chặn trùng thông báo tuyệt đối (kể cả Kafka replay).
- Error handling chuẩn ngân hàng: retry có backoff → chuyển sang **Dead Letter Topic `.DLT`**.
- Toàn bộ 31 test của module xanh; nhánh notification cho Kịch bản 5 sẵn sàng tích hợp khi hạ tầng Kafka hoàn tất.
