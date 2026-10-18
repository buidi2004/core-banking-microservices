# 🎯 BẢNG ĐIỀU PHỐI NHIỆM VỤ TÍCH HỢP APACHE KAFKA & KIỂM THỬ E2E
### Dành Cho 5 AI Agents Phụ Trách Hệ Thống Core Banking Microservices

> **Chỉ huy trưởng (Lead Orchestrator):** Antigravity AI  
> **Mục tiêu:** Tích hợp Apache Kafka (KRaft mode) vào hệ thống Core Banking Microservices theo mô hình **Dual-Broker Architecture (Kafka Event Stream + RabbitMQ Task Queue)** và triển khai bộ kiểm thử **End-to-End (E2E)** toàn diện.  
> **Nguyên tắc tài chính tối thượng:**
> 1. **Zero Data Loss:** `acks=all`, `enable.idempotence=true` và Transactional Outbox Pattern.
> 2. **Strict Chronological Ordering:** Mọi biến động số dư cùng ví bắt buộc chung Partition với Partition Key = `wallet_id`.
> 3. **Idempotent Consumer:** Chống trùng lặp tuyệt đối tại tầng Sổ cái kép (`ledger-service`).

---

## 👥 PHÂN CÔNG NHIỆM VỤ CHO 5 AI AGENTS (MAPPING HERDR PANES)

| Agent | Herdr Pane | Module Phụ Trách | Nhiệm Vụ Trọng Tâm |
|:---:|:---:|:---|:---|
| **Agent 1** | `w1:p1` | **Infrastructure & Common Library & Gateway** | Dựng Kafka KRaft Docker, viết cấu hình Kafka dùng chung trong `common-library`, điều phối E2E test runner |
| **Agent 2** | `w1:p2` | **`services/wallet-service`** | Kafka Producer cho biến động số dư ví (Partition Key: `wallet_id`) qua Outbox Relay |
| **Agent 3** | `w1:p3` | **`services/payment-service`** | Kafka Producer cho Saga Transaction Lifecycle qua Outbox Relay (Partition Key: `transaction_id`) |
| **Agent 4** | `w1:p4` | **`services/ledger-service`** | Kafka Consumer Group `ledger-posting-group`, hạch toán sổ cái kép bất biến & Idempotent Consumer |
| **Agent 5** | `w1:p5` | **`services/notification-service`** | Consumer Bridge và Xác thực kiểm thử luồng toàn trình E2E (gRPC + Kafka + Ledger + RabbitMQ FCM) |

---

## 📋 CHI TIẾT GÓI CÔNG VIỆC TỪNG AGENT

### 🛡️ AGENT 1 (Pane `w1:p1`): Infrastructure & Common Library
1. **Hạ tầng Docker (`docker-compose.yml`):**
   - Bổ sung service `kafka` (Chế độ KRaft, không dùng Zookeeper) trên Port `9092` (nội bộ) và `29092` (host).
   - Bổ sung service `kafka-ui` trên Port `8090` để giám sát Topic, Partition và Consumer Lag trực quan.
2. **Thư viện dùng chung (`common-library`):**
   - Khai báo dependency `spring-kafka` trong `common-library/pom.xml`.
   - Tạo class cấu hình chuẩn `KafkaTopicConstants`:
     - `TOPIC_WALLET_BALANCE_CHANGED = "banking.wallet.balance-changed.v1"` (6 Partitions)
     - `TOPIC_PAYMENT_TRANSACTION_LIFECYCLE = "banking.payment.transaction-lifecycle.v1"` (6 Partitions)
   - Cung cấp `KafkaEventEnvelope<T>` chứa metadata: `eventId`, `traceId`, `timestamp`, `producerService`, `payload`.
   - Cung cấp Base Producer và Base Error Handler (Dead Letter Topic `.DLT`).
3. **Maven Build:** Chạy `mvn clean install -pl common-library -DskipTests` để các service khác có thể kế thừa ngay.

---

### 💳 AGENT 2 (Pane `w1:p2`): Wallet Service (Producer)
1. **Dependency:** Bổ sung `common-library` và `spring-kafka` vào `services/wallet-service/pom.xml`.
2. **Cấu hình Kafka Producer:**
   - `bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}`
   - `acks: all`
   - `enable.idempotence: true`
   - `key-serializer: StringSerializer`, `value-serializer: JsonSerializer`.
3. **Tích hợp Transactional Outbox Relay:**
   - Nâng cấp tiến trình quét outbox để publish event biến động số dư ví vào topic:
     `banking.wallet.balance-changed.v1`.
   - **BẮT BUỘC:** Set message key = `walletId.toString()` để Kafka phân phối toàn bộ giao dịch của ví này vào duy nhất 1 Partition (Strict Ordering).
4. **Kiểm thử:** Viết `WalletKafkaProducerIntegrationTest` kiểm tra event được publish thành công kèm đúng message key.

---

### 🔄 AGENT 3 (Pane `w1:p3`): Payment Service (Saga Producer)
1. **Dependency:** Bổ sung `spring-kafka` vào `services/payment-service/pom.xml`.
2. **Cấu hình Kafka Producer:** Cấu hình chuẩn ngân hàng (`acks=all`, retry backoff).
3. **Tích hợp Saga Lifecycle Stream:**
   - Trong `PaymentSagaOrchestrator`, sau mỗi state transition (`INITIATED` -> `FUNDS_LOCKED` -> `COMPLETED` hoặc `REVERSED`), lưu event vào bảng `outbox_events`.
   - Outbox Relay publish event vào topic: `banking.payment.transaction-lifecycle.v1`.
   - Set message key = `transactionId.toString()`.
4. **Kiểm thử:** Viết unit/integration test mô phỏng khi Saga chuyển trạng thái thì Kafka Producer bắn đúng payload và key.

---

### 📖 AGENT 4 (Pane `w1:p4`): Ledger Service (Idempotent Consumer)
1. **Dependency:** Bổ sung `spring-kafka` vào `services/ledger-service/pom.xml`.
2. **Cấu hình Kafka Consumer:**
   - `group-id: ledger-posting-group`
   - `auto-offset-reset: earliest`
   - `enable-auto-commit: false` (Sử dụng Manual Immediate Ack để đảm bảo không mất event).
3. **Tích hợp Kafka Listener & Idempotency:**
   - Tạo `LedgerKafkaConsumer` lắng nghe 2 topic: `banking.wallet.balance-changed.v1` và `banking.payment.transaction-lifecycle.v1`.
   - Áp dụng bộ lọc chống trùng lặp: Kiểm tra `idempotency_key` / `reference` trước khi hạch toán.
   - Hạch toán 1 Nợ (DEBIT) - 1 Có (CREDIT) vào `ledger_postings`.
   - Sau khi hạch toán DB thành công $\rightarrow$ gọi `acknowledgment.acknowledge()`.
4. **Kiểm thử E2E:**
   - Viết test **Kịch bản 1 (Strict Ordering)**: Nạp tiền -> Rút tiền -> Nạp tiền trên cùng 1 ví, kiểm tra thứ tự offset và số dư không bao giờ bị âm.
   - Viết test **Kịch bản 2 (Idempotent Consumer)**: Giả lập đẩy trùng event, đảm bảo DB không bị ghi 2 lần.

---

### 🔔 AGENT 5 (Pane `w1:p5`): Notification Service & E2E Flow Validator
1. **Giữ vững mô hình Dual-Broker:**
   - `notification-service` tiếp tục nhận task thông báo tức thời qua RabbitMQ hoặc bổ sung Kafka Listener cho topic `banking.payment.transaction-lifecycle.v1`.
   - Bắn FCM Push Notification và WebSocket STOMP tới người dùng khi nhận event hoàn tất giao dịch.
2. **Xây dựng kịch bản kiểm thử E2E Toàn trình (Kịch bản 5):**
   - Viết kịch bản kiểm thử tích hợp: Client gọi chuyển tiền qua Gateway (8080) -> Payment gọi gRPC LockFunds sang Wallet (9090) -> Payment bắn Kafka event -> Ledger consume và ghi sổ kép -> Notification bắn FCM/WebSocket realtime.
   - Đo thời gian xử lý toàn trình (SLO: Toàn bộ chuỗi hoàn tất dưới 2 giây).

---

## ⏱️ TRÌNH TỰ THỰC THI ĐỒNG BỘ
```
Bước 1: AGENT 1 cập nhật docker-compose.yml và build common-library (Xong trước)
Bước 2: AGENT 2 & AGENT 3 tích hợp Kafka Producer trong Wallet & Payment
Bước 3: AGENT 4 tích hợp Kafka Consumer trong Ledger Service
Bước 4: AGENT 5 cùng AGENT 4 & 1 chạy bộ kiểm thử E2E xác thực toàn hệ thống
```
