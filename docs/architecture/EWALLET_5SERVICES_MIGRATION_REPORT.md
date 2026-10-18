# BÁO CÁO KỸ THUẬT: KẾ HOẠCH PHÂN RÃ HỆ THỐNG VÍ ĐIỆN TỬ MONOLITH THÀNH 5 MICROSERVICES (ZERO-CODE ARCHITECTURAL BLUEPRINT)

> **Tài liệu chiến lược kiến trúc dành cho Tech Lead, Solution Architect & Development Team.**  
> **Dựa trên đồ thị mã nguồn thực tế:** Spring Boot 3.2.5, Hexagonal DDD, 29 Controllers, 38 Use Cases, 30 Ports, 18 JPA Entities, Flyway V1->V12.  
> **Trạng thái:** Bản thiết kế & quy hoạch ranh giới (Blueprint & Boundaries - Zero-Code).

---

## 1. BỐI CẢNH & HIỆN TRẠNG KIẾN TRÚC MONOLITH (AS-IS)

Hệ thống Ví điện tử hiện nay đang được tổ chức theo mô hình **Modular Monolith** kết hợp **Hexagonal Architecture (Ports & Adapters)** và **Domain-Driven Design (DDD)**:
- **Presentation Layer:** 29 REST Controllers tiếp nhận toàn bộ các luồng Auth, Wallet, Transfer, Bill, KYC, Device, Ledger, Notification.
- **Application Layer:** 38 Use Cases và 31 Services điều phối logic tài chính, khóa phân tán Redis, và Transactional Outbox.
- **Domain Layer:** 50 Models nghiệp vụ độc lập, quản lý logic lõi (Double-Entry Ledger, Idempotency, Limit Checking).
- **Infrastructure Layer:** 1 cơ sở dữ liệu PostgreSQL dùng chung (18 JPA Entities, 12 Flyway Migrations), 1 Redis Cluster (Distributed Locks, Sessions, OTP), 1 RabbitMQ Message Broker (Outbox Relay và 4 Consumers).

### Lý do cần phân rã thành 5 Microservices:
1. **Cô lập vùng ảnh hưởng (Blast Radius Isolation):** Lỗi nghẽn I/O khi xuất hóa đơn hoặc gửi push notification không được phép làm treo luồng thanh toán và biến động số dư.
2. **Khả năng mở rộng độc lập (Independent Scalability):** `Wallet Service` và `Payment Service` cần mở rộng theo chiều ngang (High Concurrency, CPU & Memory) trong các đợt flash-sale, trong khi `Identity Service` hoặc `Ledger Service` có mô hình tải và I/O hoàn toàn khác biệt.
3. **Phân quyền truy cập & Bảo mật dữ liệu (PCI-DSS & Financial Compliance):** Cơ sở dữ liệu tài chính (Ledger, Ví) cần chính sách mã hóa, backup và quyền hạn khắt khe hơn nhiều so với dữ liệu thông báo hoặc thông tin cá nhân.
4. **Tối ưu hóa chu kỳ CI/CD:** Các nhóm phát triển có thể release độc lập các tính năng mới (Promotion, Bill Payment) mà không cần build, test và deploy lại toàn bộ khối Core Wallet.

---

## 2. QUY HOẠCH 5 BOUNDED CONTEXTS & 5 MICROSERVICES ĐÍCH (TO-BE)

Hệ thống được phân rã thành **5 Microservices độc lập**, bảo toàn triệt để kiến trúc Hexagonal bên trong mỗi service:

```
                                      +--------------------------+
                                      |   Client Mobile & Web    |
                                      +--------------------------+
                                                   |
                                                   v (HTTPS)
                                      +--------------------------+
                                      |       API GATEWAY        |
                                      |  (JWT Verify, RateLimit) |
                                      +--------------------------+
                                         /   |     |     |    \
                      +-----------------+    |     |     |     +-----------------+
                      |                      |     |     |                       |
                      v                      v     |     v                       v
               +--------------+     +------------+ | +------------+     +------------------+
               | 1. IDENTITY  |     |  2. WALLET | | |  4. LEDGER |     | 5. NOTIFICATION  |
               |   SERVICE    |     |    CORE    | | |  & AUDIT   |     |  & ENGAGEMENT    |
               +--------------+     +------------+ | +------------+     +------------------+
                      |                    ^       |        ^                    ^
                      |                    | (gRPC)|        | (AMQP Events)      | (AMQP Events)
                      |                    +-------+        +----------+         |
                      |                            |                   |         |
                      |                     +-------------+            |         |
                      |                     | 3. PAYMENT  |------------+---------+
                      |                     |   ENGINE    | (Transactional Outbox)
                      |                     +-------------+
                      v                            |
                [Redis Session]                    v
                                          [Napas 247 / VietQR]
```

---

### DỊCH VỤ 1: `IDENTITY-SERVICE` (AUTH, USER & EKYC)
- **Ranh giới nghiệp vụ:** Quản lý vòng đời tài khoản định danh, thông tin người dùng, hồ sơ eKYC, phiên đăng nhập đa thiết bị và điều khoản pháp lý.
- **Controllers tiếp nhận (7 Controllers):**
  - `AuthController`: Đăng ký, đăng nhập, cấp phát JWT, OTP đăng ký.
  - `UserController`: Tra cứu và quản lý người dùng.
  - `ProfileController`: Cập nhật thông tin cá nhân, avatar.
  - `SessionController`: Danh sách thiết bị đăng nhập, thu hồi session từ xa.
  - `SecurityController`: Cấu hình 2FA, sinh trắc học, đổi mã PIN.
  - `AccountController`: Đổi mật khẩu, quên mật khẩu.
  - `LegalConfigController`: Quản lý điều khoản sử dụng, chính sách bảo mật.
- **Application Services / Use Cases:**
  - `AuthService`, `UserService`, `ProfileService`, `SessionService`, `SecurityService`, `AccountService`, `OtpService`, `LegalConfigService`.
- **Database riêng (`ewallet_identity_db`):**
  - Bảng: `users`, `user_profiles`, `user_kycs`, `user_sessions`.
  - Redis chuyên dụng: OTP Cache (`otp:user:{userId}`), Session Store, Token Blacklist.
- **Sự kiện phát hành (Domain Events):**
  - `UserRegisteredEvent`, `KycStatusUpdatedEvent`, `UserStatusChangedEvent`, `UserSessionTerminatedEvent`.

---

### DỊCH VỤ 2: `WALLET-SERVICE` (WALLET CORE & BALANCE SERVICE)
- **Ranh giới nghiệp vụ:** Trọng tài tối cao về số dư (Single Source of Truth for Balance). Chịu trách nhiệm khóa số dư, kiểm tra hạn mức giao dịch (theo cấp độ KYC), cộng/trừ tiền an toàn tuyệt đối.
- **Controllers tiếp nhận (2 Controllers):**
  - `WalletController`: Các endpoint xem số dư, thông tin ví (`/api/v1/wallets/me`, `/api/v1/wallets/{id}`), nạp/rút nội bộ.
  - `ReconciliationController`: Đối soát số dư nội bộ các ví.
- **Application Services / Use Cases:**
  - `WalletService` (core balance logic), `FeeEstimationService`, `ReconciliationService`.
- **Database riêng (`ewallet_wallet_db`):**
  - Bảng: `wallets`.
  - Redis chuyên dụng: Khóa phân tán `lock:wallet:{walletId}` (Redlock), hạn mức giao dịch lũy kế trong ngày/tháng (`limit:wallet:{walletId}:daily`).
- **Giao diện kết nối nội bộ (Private gRPC / REST API):**
  - `debitWallet(walletId, amount, transactionId)`: Trừ số dư với Pessimistic Lock (`SELECT FOR UPDATE`).
  - `creditWallet(walletId, amount, transactionId)`: Cộng số dư với Pessimistic Lock.
  - `reserveBalance(walletId, amount, transactionId)`: Giữ chỗ số dư (cho luồng 2-phase transfer).
  - `releaseBalance(walletId, amount, transactionId)`: Giải phóng giữ chỗ nếu giao dịch bị hủy.
  - `checkLimit(walletId, amount)`: Kiểm tra hạn mức ngày/tháng theo trạng thái KYC.
- **Sự kiện phát hành (Domain Events):**
  - `WalletCreatedEvent`, `WalletDebitedEvent`, `WalletCreditedEvent`, `WalletLimitExceededEvent`.

---

### DỊCH VỤ 3: `PAYMENT-SERVICE` (TRANSACTION & SAGA ORCHESTRATOR)
- **Ranh giới nghiệp vụ:** Động cơ điều phối giao dịch thanh toán toàn trình. Xử lý chuyển tiền P2P, tạo/quét VietQR chuẩn EMVCo, thanh toán hóa đơn cước, yêu cầu đòi tiền (Money Request / Split Bill), liên kết tài khoản ngân hàng đối tác và điều phối luồng Saga Compensating Transaction (Auto-Reversal).
- **Controllers tiếp nhận (9 Controllers):**
  - `PaymentController`: Khởi tạo và xác nhận chuyển tiền.
  - `QrController`: Sinh mã VietQR, thanh toán mã QR động/tĩnh.
  - `MoneyRequestController`: Tạo, chấp nhận, từ chối và chia tiền.
  - `BillPaymentController`: Tra cứu cước và gạch nợ hóa đơn bên thứ ba.
  - `BankAccountController` & `BankController`: Liên kết ngân hàng, danh sách Napas.
  - `FundingSourceController`: Quản lý các nguồn tiền thanh toán.
  - `BeneficiaryController`: Danh bạ người thụ hưởng thường dùng.
  - `PartnerWebhookController`: Tiếp nhận callback/webhook từ Napas và nhà cung cấp.
  - `ReceiptController`: Truy vấn biên lai thanh toán.
- **Application Services / Use Cases:**
  - `PaymentService`, `PersonalQrService`, `VietQrService`, `MoneyRequestService`, `BankService`, `FundingSourceService`, `BeneficiaryService`, `PartnerWebhookService`, `ReceiptService`, `TransactionReversalService` (Saga Orchestrator), `OutboxHelper`.
- **Database riêng (`ewallet_payment_db`):**
  - Bảng: `transactions`, `money_requests`, `banks`, `bank_accounts`, `funding_sources`, `beneficiaries`, `outbox_events`.
  - Redis chuyên dụng: Idempotency Key cache (`idempotency:{key}`), Dynamic QR payload cache.
- **Mô hình giao dịch tin cậy:**
  - **IdempotencyFilter:** Chống duplicate request ở tầng mạng.
  - **Transactional Outbox Pattern + OutboxRelayScheduler:** Đảm bảo 100% sự kiện giao dịch được gửi vào RabbitMQ mà không bị mất mát khi crash.
  - **Saga Orchestrator:** Điều phối trạng thái `INITIATED` -> `PROCESSING` -> `SUCCESS` hoặc `REVERSED` (tự động kích hoạt bù trừ hoàn tiền nếu cổng thanh toán bên thứ ba thất bại).
- **Sự kiện phát hành (Domain Events vào RabbitMQ):**
  - `TransactionInitiatedEvent`, `TransactionCompletedEvent`, `TransactionFailedEvent`, `TransactionReversedEvent`.

---

### DỊCH VỤ 4: `LEDGER-SERVICE` (GENERAL LEDGER & AUDIT SERVICE)
- **Ranh giới nghiệp vụ:** Trung tâm kế toán tài chính và nhật ký kiểm toán. Tuân thủ nghiêm ngặt nguyên lý kế toán kép (Double-Entry Bookkeeping): `Sum(Debit) = Sum(Credit)`. Lưu vết kiểm toán bất biến (Immutable Audit Trail) phục vụ thanh tra ngân hàng và cơ quan quản lý.
- **Controllers tiếp nhận (2 Controllers):**
  - `LedgerController`: Tra cứu sổ cái tài chính, tài khoản kế toán (`/api/v1/ledger/**`).
  - `TransactionQueryController`: Tra cứu lịch sử giao dịch chuyên sâu, xuất sao kê chi tiết.
- **Application Services / AMQP Consumers:**
  - `LedgerService`, `LedgerConsumer`, `AuditLogConsumer`.
- **Database riêng (`ewallet_ledger_db`):**
  - Bảng: `journal_entries`, `ledger_postings`, `ledger_accounts`, `audit_logs`.
  - Thiết kế database: **Append-Only** (Không cho phép UPDATE hay DELETE dữ liệu kế toán).
- **Cơ chế hoạt động:**
  - Lắng nghe bất đồng bộ các event tài chính (`TransactionCompletedEvent`, `TransactionReversedEvent`) từ RabbitMQ Exchange `wallet.exchange`.
  - `LedgerConsumer`: Tự động sinh `JournalEntry` và các dòng `LedgerPosting` (Tài khoản người gửi ghi Có, tài khoản người nhận ghi Nợ, hoặc tài khoản trung gian ví).
  - `AuditLogConsumer`: Ghi log kiểm toán phi đồng bộ, giải phóng độ trễ của giao dịch chính.

---

### DỊCH VỤ 5: `NOTIFICATION-SERVICE` (NOTIFICATION & ENGAGEMENT SERVICE)
- **Ranh giới nghiệp vụ:** Trung tâm truyền thông đa kênh thời gian thực và tương tác người dùng. Bắn push notification qua Firebase Cloud Messaging (FCM), đẩy WebSocket STOMP tới ứng dụng di động, quản lý mã khuyến mại (Voucher), chăm sóc khách hàng (Support Ticket), đánh giá (Feedback) và tiếp thị liên kết (Referral).
- **Controllers tiếp nhận (6 Controllers):**
  - `NotificationController`: Tra cứu hòm thư thông báo in-app, đánh dấu đã đọc.
  - `DeviceController`: Đăng ký và quản lý FCM device token.
  - `FeedbackController`: Tiếp nhận phản hồi trải nghiệm người dùng.
  - `SupportController`: Tạo và theo dõi phiếu yêu cầu hỗ trợ.
  - `PromotionController`: Tra cứu ưu đãi, áp dụng mã voucher.
  - `ReferralController`: Mã giới thiệu và chương trình nhận thưởng.
- **Application Services / AMQP Consumers:**
  - `NotificationService`, `DeviceTokenService`, `FeedbackService`, `SupportService`, `PromotionService`, `ReferralService`.
  - `NotificationConsumer`, `ReceiptGenerationConsumer`.
  - `FirebaseFcmNotificationAdapter`, `WebSocketNotificationAdapter`.
- **Database riêng (`ewallet_notification_db`):**
  - Bảng: `notifications`, `device_tokens`, `vouchers`, `promotions`, `support_tickets`, `feedbacks`, `referrals`.
- **Cơ chế hoạt động:**
  - Tiêu thụ `TransactionCompletedEvent` từ RabbitMQ: Trích xuất số điện thoại người gửi/nhận, đẩy thông báo biến động số dư qua FCM (app chạy ngầm) và WebSocket (app đang mở).

---

## 3. CHIẾN LƯỢC CƠ SỞ DỮ LIỆU (DATABASE-PER-SERVICE)

### 3.1. Bảng phân bổ Schema từ 12 Flyway Migrations hiện tại

| Flyway Script Gốc | Bảng Dữ Liệu | Microservice Sở Hữu | Database Đích |
|---|---|---|---|
| `V1__init_schema.sql` | `users`, `user_profiles`, `user_kycs` | **Identity Service** | `ewallet_identity_db` |
| `V1__init_schema.sql` | `wallets` | **Wallet Service** | `ewallet_wallet_db` |
| `V1__init_schema.sql` | `transactions`, `beneficiaries` | **Payment Service** | `ewallet_payment_db` |
| `V1__init_schema.sql` | `journal_entries`, `ledger_postings`, `ledger_accounts`, `audit_logs` | **Ledger Service** | `ewallet_ledger_db` |
| `V2__add_extended_modules.sql` | `bills`, `merchants` | **Payment Service** | `ewallet_payment_db` |
| `V2__add_extended_modules.sql` | `vouchers`, `feedback`, `support_tickets`, `referrals` | **Notification Service** | `ewallet_notification_db` |
| `V3__add_session_table.sql` | `user_sessions` | **Identity Service** | `ewallet_identity_db` |
| `V4__add_funding_sources_table.sql` | `funding_sources` | **Payment Service** | `ewallet_payment_db` |
| `V6__add_banks_and_update_transactions.sql` | `banks`, `bank_accounts` | **Payment Service** | `ewallet_payment_db` |
| `V9__create_outbox_events.sql` | `outbox_events` | **Payment Service** (và cục bộ mỗi service phát sinh event) | `ewallet_payment_db` |
| `V12__create_device_tokens_table.sql` | `device_tokens`, `notifications` | **Notification Service** | `ewallet_notification_db` |

### 3.2. Quy tắc loại bỏ Khóa ngoại vật lý (Foreign Key Decoupling)
Trong kiến trúc Monolith, các bảng liên kết chặt chẽ qua Foreign Key (ví dụ `wallets.user_id REFERENCES users(id)`, `transactions.source_wallet_id REFERENCES wallets(id)`).
Khi phân rã microservices:
1. **Thay thế Foreign Key bằng Logical Identifier (UUID/Correlation ID):**
   - Bảng `wallets` lưu `user_id` dạng `VARCHAR(36)` đơn thuần, không khai báo foreign key sang database identity.
   - Bảng `transactions` lưu `source_wallet_id` và `target_wallet_id` dạng `VARCHAR(36)`.
2. **Không thực hiện JOIN xuyên cơ sở dữ liệu:**
   - Các API cần thông tin tổng hợp (VD: Hiển thị tên người nhận tiền khi nhập SĐT) sẽ gọi qua API nội bộ hoặc sử dụng kỹ thuật **Data Replication / Read Projection** thông qua lắng nghe sự kiện domain.

---

## 4. CHIẾN LƯỢC GIAO TIẾP LIÊN DỊCH VỤ & GIAO DỊCH PHÂN TÁN (SAGA PATTERN)

### 4.1. Ma trận Giao Tiếp (Synchronous vs Asynchronous)

| Chiều Giao Tiếp | Giao Thức | Mục Đích | Đặc Tính Kỹ Thuật |
|---|---|---|---|
| **Client -> API Gateway** | HTTPS / REST, WSS | Tiếp nhận request từ Mobile/Web | Reverse Proxy, Rate Limiter |
| **API Gateway -> Microservices** | HTTP/2 REST | Định tuyến nghiệp vụ | Gắn Header `X-User-Id`, `X-User-Phone` |
| **Payment Service -> Wallet Service** | **gRPC / Protobuf** | Khóa số dư, trừ tiền, cộng tiền tức thời | Độ trễ < 5ms, Strict Concurrency |
| **Payment Service -> Identity Service** | **gRPC** | Kiểm tra trạng thái User (Active, Kyc Tier, mã PIN) | Cache trong Redis |
| **Payment Service -> RabbitMQ** | AMQP (Outbox Relay) | Xuất bản `TransactionCompletedEvent` | Đảm bảo At-Least-Once Delivery |
| **RabbitMQ -> Ledger Service** | AMQP Consumer | Hạch toán sổ cái kép (Nợ / Có) | Bất đồng bộ, Idempotent |
| **RabbitMQ -> Notification Service**| AMQP Consumer | Gửi Push FCM và WebSocket | Bất đồng bộ, không chặn luồng tiền |

---

### 4.2. Luồng Thực Thi Giao Dịch Chuyển Tiền P2P (Orchestrated Saga Sequence)

```
Client         API Gateway      Payment Engine      Wallet Core       RabbitMQ       Ledger Svc    Notification Svc
  |                 |                 |                  |                |              |                |
  |--- POST /transfer (Idempotency) ->|                  |                |              |                |
  |                 |                 |-- 1. Create Tx   |                |              |                |
  |                 |                 |   (INITIATED)    |                |              |                |
  |                 |                 |                  |                |              |                |
  |                 |                 |-- 2. gRPC Debit ->| (Redis Lock    |              |                |
  |                 |                 |   Wallet A       |  SELECT FOR    |              |                |
  |                 |                 |                  |  UPDATE)       |              |                |
  |                 |                 |<- Debit Success --|                |              |                |
  |                 |                 |                  |                |              |                |
  |                 |                 |-- 3. gRPC Credit->|                |              |                |
  |                 |                 |   Wallet B       | (SELECT FOR    |              |                |
  |                 |                 |                  |  UPDATE)       |              |                |
  |                 |                 |<- Credit Success -|                |              |                |
  |                 |                 |                  |                |              |                |
  |                 |                 |-- 4. Mark Tx     |                |              |                |
  |                 |                 |   SUCCESS & write|                |              |                |
  |                 |                 |   Outbox Event --|                |              |                |
  |                 |                 |   (1 DB Tx)      |                |              |                |
  |<- 200 OK (Tx Completed) ----------|                  |                |              |                |
                                      |                  |                |              |                |
                                      | (Outbox Relay)---|                |              |                |
                                      |   quét event & publish ---------->|              |                |
                                                                          |--- Event --->|                |
                                                                          |   to Ledger  |-- Ghi Sổ Kép --|
                                                                          |              |   Debit = Credit
                                                                          |              |                |
                                                                          |--- Event -------------------->|
                                                                              to Notify  |-- FCM Push ----|
                                                                                         |-- WebSocket ---|
```

### Xử lý thất bại (Saga Compensating Transaction):
- Nếu bước 2 (Debit Wallet A) thất bại (Không đủ số dư, vượt hạn mức, hoặc lỗi kết nối): Payment Engine đánh dấu giao dịch `FAILED`, trả lỗi ngay cho client. Không phát sinh Outbox event.
- Nếu bước 2 thành công nhưng bước 3 (Credit Wallet B) bị lỗi hoặc timeout:
  - Saga Orchestrator kích hoạt **Bù trừ hoàn tiền (Compensating Step)**.
  - Gọi gRPC hoàn tiền cho Wallet A: `creditWallet(walletA, amount, "REVERSAL_" + txId)`.
  - Cập nhật trạng thái giao dịch thành `REVERSED`.
  - Ghi Outbox Event `TransactionReversedEvent` để thông báo cho người dùng về việc giao dịch đã được tự động hoàn tiền.

---

## 5. PHÂN BỔ CACHE, KHÓA PHÂN TÁN VÀ ĐỒNG BỘ DỮ LIỆU

### 5.1. Phân Vùng Redis Cache (Namespace Isolation)
Thay vì dùng chung 1 Redis key-space hỗn loạn, quy hoạch prefix rõ ràng theo từng service:
- `identity:*`:
  - `identity:otp:{userId}`: Mã OTP xác thực (TTL 3m).
  - `identity:session:{token}`: Quản lý phiên đăng nhập và danh sách thiết bị.
  - `identity:blacklist:{jwtId}`: Token đã logout (TTL 5m theo hạn JWT).
- `wallet:*`:
  - `wallet:lock:{walletId}`: Khóa phân tán Redlock cho các thao tác tác động số dư.
  - `wallet:limit:{walletId}:{yyyyMMdd}`: Bộ đếm hạn mức giao dịch trong ngày.
- `payment:*`:
  - `payment:idempotency:{key}`: Cache kết quả xử lý giao dịch chống trùng lặp.
  - `payment:qr:{qrCodeId}`: Payload mã QR động có thời hạn thanh toán.
- `notification:*`:
  - `notification:device:{userId}`: Cache danh sách thiết bị FCM active.

---

## 6. LỘ TRÌNH CHUYỂN ĐỔI AN TOÀN (STRANGLER FIG PATTERN - 4 GIAI ĐOẠN)

Việc phân rã được thực hiện tuần tự theo mẫu **Strangler Fig Pattern**, đảm bảo hệ thống đang chạy không bị gián đoạn:

### Giai đoạn 1: Dựng API Gateway & Tách `Notification Service` (Tuần 1 - 2)
- **Mục tiêu:** Dựng API Gateway phía trước Monolith; bóc tách phân hệ ít rủi ro tài chính nhất là Notification.
- **Thực hiện:**
  - Thiết lập API Gateway định tuyến toàn bộ traffic vào Monolith hiện tại.
  - Khởi tạo repo/module `notification-service`, chuyển các entity `notifications`, `device_tokens`, `vouchers`, các controller và adapter Firebase FCM/WebSocket sang service mới.
  - Monolith khi hoàn tất giao dịch chỉ cần ghi Outbox Event bắn vào RabbitMQ. `Notification Service` độc lập tiêu thụ và gửi push.
  - **Rủi ro tài chính:** 0% (Nếu notification gặp sự cố, luồng tiền vẫn an toàn).

### Giai đoạn 2: Tách `General Ledger & Audit Service` (Tuần 3 - 4)
- **Mục tiêu:** Độc lập hóa dữ liệu kế toán và nhật ký kiểm toán.
- **Thực hiện:**
  - Tách các bảng `journal_entries`, `ledger_postings`, `ledger_accounts`, `audit_logs` sang database `ewallet_ledger_db`.
  - Đưa `LedgerConsumer` và `AuditLogConsumer` sang service riêng.
  - Chuyển toàn bộ các endpoint tra cứu sao kê lịch sử từ `TransactionQueryController` và `LedgerController` qua API Gateway định tuyến tới `Ledger Service`.

### Giai đoạn 3: Tách `Identity & Auth Service` (Tuần 5 - 6)
- **Mục tiêu:** Tách định danh, eKYC và xác thực.
- **Thực hiện:**
  - Tách các bảng `users`, `user_profiles`, `user_kycs`, `user_sessions` sang `ewallet_identity_db`.
  - API Gateway đảm nhận xác thực JWT tập trung: Giải mã token, kiểm tra blacklist trên Redis, inject thông tin user vào header request trước khi forward tới các dịch vụ bên dưới.

### Giai đoạn 4: Phân tách Lõi Tài Chính: `Wallet Service` vs `Payment Engine` (Tuần 7 - 9)
- **Mục tiêu:** Hoàn tất phân rã 2 dịch vụ cốt lõi quan trọng nhất.
- **Thực hiện:**
  - Định nghĩa hợp đồng giao tiếp gRPC (Protobuf contracts) cho các thao tác: `Debit`, `Credit`, `Reserve`, `Release`, `CheckLimit`.
  - Tách `wallets` sang `ewallet_wallet_db`. `Wallet Service` giữ nguyên cơ chế `SELECT FOR UPDATE` và Redis Distributed Lock.
  - `Payment Service` giữ lại `transactions`, `money_requests`, liên kết ngân hàng và đóng vai trò **Saga Orchestrator**.
  - Kiểm thử toàn trình (E2E Integration Test) luồng chuyển tiền chịu tải cao và kiểm thử kịch bản bù trừ tự động (Auto-Reversal).

---

## 7. TỔNG KẾT ARTIFACTS & TÀI LIỆU KÈM THEO

1. **Sơ đồ Kiến Trúc Tương Tác 5 Microservices (Archify Showcase Passed):**
   - File JSON đặc tả: [ewallet-5services.architecture.json](file:///home/buidi/app-mono-di-va-khoa/docs/architecture/ewallet-5services.architecture.json)
   - File HTML hiển thị trực quan (Interactive SVG): [ewallet-5services.html](file:///home/buidi/app-mono-di-va-khoa/docs/architecture/ewallet-5services.html)
   - Đạt chuẩn Showcase với 9/9 tiêu chí xác thực (0 errors, 0 warnings).
2. **Kế hoạch hành động tiếp theo:**
   - Review và thống nhất ranh giới phân rã giữa các domain.
   - Khi sẵn sàng bước vào code, bắt đầu triển khai từ **Giai đoạn 1 (API Gateway & Notification Service)**.
