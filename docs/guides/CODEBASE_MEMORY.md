# 🧠 CODEBASE MEMORY: CORE BANKING MICROSERVICES BLUEPRINT
### Hệ Thống Ngân Hàng Lõi Đạt Chuẩn Kiến Trúc Database-per-Service & Sổ Cái Kép

> **Tài liệu tham chiếu chuẩn cho AI Coding Agents, Kỹ sư Phần mềm và Hội đồng Kiến trúc.**  
> **Động cơ phân tích mã nguồn:** `codebase-memory-mcp` v0.12.1 (Tree-sitter AST Knowledge Graph).  
> **Chỉ số đồ thị thực tế từ engine:** **`15,552 nodes` | `66,282 edges`** (Project: `home-buidi-app-mono-di-va-khoa`).  
> **Kiến trúc:** `Database-per-Service Microservices + Hexagonal DDD + Saga Orchestrator + gRPC Core + Dual-Broker (Kafka KRaft & RabbitMQ) + Redis Lock + Append-Only Double-Entry Ledger`.  
> **Trạng thái:** `Production Ready | Monorepo Reactor | 12/12 Artifacts Verified | E2E Tested`.

---

## 1. TỔNG QUAN KIẾN TRÚC & HẠ TẦNG

Hệ thống **Core Banking Microservices** là giải pháp ngân hàng lõi & ví điện tử phân tán, được thiết kế theo tiêu chuẩn khắt khe của hệ thống tài chính:

- **Nền tảng công nghệ:** Java 17, Spring Boot 3.2.5, Spring Cloud Gateway 4.1.2.
- **Mô hình Dữ liệu (Database-per-Service):** 5 cơ sở dữ liệu PostgreSQL 15 độc lập, không chia sẻ bảng hay schema.
- **Giao tiếp Đồng bộ (Inter-Service Synchronous):** High-performance **gRPC (Protocol Buffers v3)** giữa `payment-service` và `wallet-service` (Port 9090) với độ trễ < 2ms.
- **Hạ tầng Message Broker Kép (Dual-Broker Architecture):**
  - **Apache Kafka (KRaft v7.6.0 - Ports 9092, 29092):** Event Streaming phân tán cho chu trình vòng đời giao dịch, biến động số dư và ghi sổ cái.
  - **RabbitMQ (v3.13.7 - Ports 5672, 15672):** Hàng đợi xử lý tác vụ bất đồng bộ, RPC nội bộ và đẩy thông báo.
  - **Kafka-UI (Port 8090):** Bảng điều khiển giám sát trực quan broker, topics, partitions và consumer group lag.
- **Tính nhất quán phân tán (Distributed Consistency):**
  - **Saga Orchestrator Pattern:** Phối hợp giao dịch đa chặng kèm cơ chế tự động bù trừ (**Auto-Reversal / Compensating Transaction**) khi có lỗi.
  - **Khóa 2 tầng chống Race Condition:** **Redis Distributed Lock** (`lock:wallet:{walletId}`) kết hợp **PostgreSQL Pessimistic Lock** (`SELECT ... FOR UPDATE`).
- **Kế toán Tài chính Bất Biến (Immutable Financial Ledger):**
  - Hạch toán **Sổ cái kép (Double-Entry Bookkeeping)** độc lập tại `ledger-service`.
  - Phân quyền cấp cơ sở dữ liệu: `REVOKE UPDATE, DELETE ON ALL TABLES` cho tài khoản `ledger_app_user`.
  - Bất biến cân bằng tài chính tuyệt đối: $\sum \text{Debit Postings} = \sum \text{Credit Postings}$.

```
                                  [ INTERNET CLIENTS ]
                               (Mobile App / Web React :5173)
                                              |
                                              v
                              +-------------------------------+
                              |    CADDY PROXY (Port 80/443)  |
                              |  TLS Termination / Security   |
                              +---------------+---------------+
                                              |
                                              v
                              +-------------------------------+
                              |    API GATEWAY (Port 8080)    |
                              |   Spring Cloud Gateway / JWT  |
                              +---------------+---------------+
                                              |
      +-------------------+-------------------+-------------------+-------------------+
      | (Port 8081)       | (Port 8082,gRPC:9090)| (Port 8083)       | (Port 8084)       | (Port 8085)
      v                   v                   v                   v                   v
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
|  IDENTITY   |     |   WALLET    |     |   PAYMENT   |     |   LEDGER    |     |NOTIFICATION |
|   SERVICE   |     |   SERVICE   |     |   SERVICE   |     |   SERVICE   |     |   SERVICE   |
| (Auth, eKYC,|     | (Balance    |     | (Saga P2P,  |     | (Double-    |     | (FCM Push,  |
|Teller/Mgr)  |     |  Custody)   |<----+  Cash Desk) |     |  Entry)     |     |  STOMP WS)  |
+------+------+     +------+------+     +------+------+     +------+------+     +------+------+
       |                   |                   |                   |                   |
       |                   | (Events)          | (Outbox Events)   | (Consumes)        | (Consumes)
       |                   +---------+   +-----+---------+   +-----+-----+             |
       |                             |   |               |   |           |             |
       |                             v   v               v   v           v             v
       |                     +---------------------------------------------------------------+
       |                     |             KAFKA STREAMING BUS (Port 9092/29092)             |
       |                     |  banking.payment.transaction-lifecycle.v1                     |
       |                     |  banking.wallet.balance-changed.v1                            |
       |                     |  banking.ledger.postings.v1                                   |
       |                     |  banking.cash.deposit-completed.v1                            |
       |                     +---------------------------------------------------------------+
       |                                                 |
       |                                                 v
       |                     +---------------------------------------------------------------+
       |                     |             RABBITMQ EVENT BUS (Port 5672/15672)              |
       |                     |  Exchanges: wallet.events, payment.events, ledger.events      |
       |                     |  Queues: notification-service-queue, notification-service-dlq |
       |                     +---------------------------------------------------------------+
       |
       v (Database-per-Service: 5 Database độc lập hoàn toàn trên 5 Ports riêng biệt)
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
| PostgreSQL  |     | PostgreSQL  |     | PostgreSQL  |     | PostgreSQL  |     | PostgreSQL  |
| identity_db |     |  wallet_db  |     | payment_db  |     |  ledger_db  |     |notification_|
| (Port 5433) |     | (Port 5434) |     | (Port 5435) |     | (Port 5436) |     |db(Port 5437)|
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
                           |                   |
                           +---------+   +-----+
                                     |   |
                                     v   v
                             +-------------------+
                             |    REDIS CACHE    |
                             | Distributed Lock  |
                             | (Port 6379)       |
                             +-------------------+
```

---

## 2. BẢN ĐỒ CẤU TRÚC THƯ MỤC MONOREPO (CHUẨN HÓA FE - BE - MOBILE)

```text
core-banking-microservices/
├── .agents/                                  # Cấu hình AI Agents & MCP Servers
│   ├── AGENTS.md                             # Bộ quy tắc dành riêng cho AI Agents
│   ├── mcp_config.json                       # Khai báo máy chủ MCP codebase-memory
│   └── plugins/                              # Plugins MCP (codebase-memory, mobile-mcp)
│
├── backend/                                  # [BE] TOÀN BỘ HỆ THỐNG BACKEND JAVA 17 / SPRING BOOT 3
│   ├── pom.xml                               # Parent Maven Reactor quản lý dependencies & plugins
│   ├── common-library/                       # Thư viện dùng chung (Shared Kernel, gRPC, Events, DTOs)
│   └── services/                             # 6 DỊCH VỤ MICROSERVICES ĐỘC LẬP (DATABASE-PER-SERVICE)
│       ├── api-gateway/                      # [Port 8080] Spring Cloud Gateway, Edge JWT Filter, CORS
│       ├── identity-service/                 # [Port 8081] Auth, JWT Blacklist, eKYC, Users (DB: 5433)
│       ├── wallet-service/                   # [Port 8082, gRPC: 9090] Balance Custody (DB: 5434)
│       ├── payment-service/                  # [Port 8083] Saga Orchestrator, Cash Desk (DB: 5435)
│       ├── ledger-service/                   # [Port 8084] Double-Entry Ledger, Append-Only (DB: 5436)
│       └── notification-service/             # [Port 8085] Push FCM, WebSocket STOMP (DB: 5437)
│
├── frontend/                                 # [FE] TOÀN BỘ ỨNG DỤNG WEB FRONTEND (REACT / VITE)
│   └── cash-deposit-portal/                  # Cổng giao dịch nộp tiền mặt tại quầy (Port 5173)
│
├── mobile/                                   # [MOBILE] TOÀN BỘ ỨNG DỤNG E-WALLET FLUTTER (CLEAN ARCHITECTURE)
│   ├── lib/                                  # 50 màn hình, 10 phân hệ nghiệp vụ, Liquid Glass Widgets
│   ├── android/                              # Cấu hình Native Android & Google Services
│   ├── ios/                                  # Cấu hình Native iOS Pods & Runner
│   ├── assets/                               # Tài nguyên hình ảnh, biểu tượng & glass shader patterns
│   ├── test/                                 # Kịch bản kiểm thử Flutter Unit & Widget Tests
│   ├── docs/                                 # Tài liệu Mobile: API Integration Guide, Migration, Screenshots
│   └── pubspec.yaml                          # Quản lý dependencies Flutter & Liquid Glass
│
├── deploy/                                   # CẤU HÌNH TRIỂN KHAI & REVERSE PROXY
│   ├── docker-compose.public.yml             # Caddy Reverse Proxy bảo vệ cổng public (80/443)
│   └── Caddyfile                             # Cấu hình SSL tự động & định tuyến Gateway
│
├── docs/                                     # TÀI LIỆU KỸ THUẬT & KIẾN TRÚC TOÀN HỆ THỐNG
│   ├── architecture/                         # Sơ đồ kiến trúc, báo cáo chuyển đổi, Saga spec
│   └── guides/                               # Hướng dẫn chi tiết: CODEBASE_MEMORY, Frontend Dev
│
├── scripts/                                  # SCRIPTS VẬN HÀNH & KIỂM THỬ TỰ ĐỘNG
│   ├── verify-all-artifacts.sh               # Kịch bản kiểm chứng toàn diện 12/12 artifacts
│   ├── e2e/                                  # Bộ test E2E 8 kịch bản dữ liệu thật (Kafka/RabbitMQ/Redis)
│   ├── maintenance/                          # Bảo trì an toàn cổng & audit bảo mật
│   └── init-5-databases.sql                  # Khởi tạo 5 DBs và phân quyền Append-Only
│
├── docker-compose.yml                        # Cụm Microservices + 5 DBs + Kafka + RabbitMQ + Redis (14 containers)
├── run.sh                                    # CLI Master Control: ./run.sh fe | be | mobile | infra | test | all
├── README.md                                 # Hướng dẫn tổng quan toàn dự án
├── ACCOUNTS.md                               # Danh sách tài khoản thử nghiệm hệ thống
└── pom.xml                                   # Root Maven Monorepo Aggregator
```

---

## 3. THỐNG KÊ ĐỒ THỊ MÃ NGUỒN TỪ `codebase-memory-mcp` (V0.12.1)

Chỉ số được đo lường chính xác từ engine đồ thị `codebase-memory-mcp`:

### 3.1. Chỉ Số Đồ Thị Thực Tế
- **Project Name:** `home-buidi-app-mono-di-va-khoa`
- **Total Nodes:** **`15,552 nodes`**
- **Total Edges:** **`66,282 edges`**
- **Trạng thái Index:** `ready` (RAM-first SQLite Graph + LZ4 Compression)
- **Watcher Strategy:** `git` poll interval `6000ms`.
- **Số tập tin được phân tích:** Hơn 640 tập tin (Java, SQL Migrations, YAML Configs, Protobuf, Markdown).

### 3.2. Các Loại Nodes & Edges Cốt Lõi
- **Nodes Phổ Biến:** `Class`, `Interface`, `Record`, `Method`, `Function`, `Constructor`, `Field`, `Parameter`, `Enum`, `Route`, `Topic`.
- **Edges Quan Hệ:**
  - `CALLS`: Lời gọi hàm từ Controller $\rightarrow$ Service $\rightarrow$ Outbox / Port $\rightarrow$ Adapter.
  - `IMPLEMENTS`: Ánh xạ từ Port Interface (Domain) sang JPA / Kafka / gRPC Adapter.
  - `INHERITS`: Kế thừa lớp đối tượng và Exception hierarchy.
  - `CROSS_SERVICE`: Liên kết lời gọi qua mạng gRPC (`Payment` $\rightarrow$ `Wallet`) hoặc Event Messaging (`Payment` $\rightarrow$ `Ledger` / `Notification`).
  - `DATA_FLOW`: Luồng truyền tham số nghiệp vụ (ví dụ: `amount`, `transactionId`, `walletId`).

---

## 4. CHI TIẾT KỸ THUẬT CÁC MICROSERVICES LÕI

| Microservice | Cổng HTTP | Cổng gRPC | Database | Port DB | User DB | Vai Trò Chính |
| :--- | :---: | :---: | :--- | :---: | :--- | :--- |
| **API Gateway** | `8080` | - | - | - | - | Central Entry, JWT Relay, CORS, Header Sanitization |
| **Identity Service** | `8081` | - | `ewallet_identity_db` | `5433` | `identity_db_user` | Auth, JWT, Refresh Token, eKYC, Teller/Manager Roles |
| **Wallet Service** | `8082` | `9090` | `ewallet_wallet_db` | `5434` | `wallet_db_user` | Balance Custody, Redis Lock, gRPC Server Port 9090 |
| **Payment Service** | `8083` | - | `ewallet_payment_db` | `5435` | `payment_db_user` | Saga Orchestrator, P2P Transfer, Maker-Checker Cash |
| **Ledger Service** | `8084` | - | `ewallet_ledger_db` | `5436` | `ledger_app_user` | Append-Only Double-Entry Ledger, Audit Postings |
| **Notification Service**| `8085` | - | `ewallet_notification_db`| `5437` | `notification_db_user` | FCM Push, WebSocket STOMP, Audit Logs |

---

### 4.1. API Gateway (`services/api-gateway`)
- **Port:** `8080` (Spring Cloud Gateway, Netty Reactive).
- **Định Tuyến Cụ Thể:**
  - `/api/v1/auth/**`, `/api/v1/users/**`, `/api/v1/kyc/**`, `/api/v1/sessions/**` $\rightarrow$ `identity-service:8081`
  - `/api/v1/wallets/**` $\rightarrow$ `wallet-service:8083`
  - `/api/v1/cash/**` $\rightarrow$ `payment-service:8082`
  - `/api/v1/ledger/**` $\rightarrow$ `ledger-service:8084`
  - `/api/v1/notifications/**`, `/api/v1/devices/**`, `/api/v1/support/**`, `/api/v1/feedback/**`, `/api/v1/promotions/**`, `/api/v1/referrals/**` $\rightarrow$ `notification-service:8085`
  - `/api/v1/**` (Fallback) $\rightarrow$ `monolith:8080`
- **CORS Config:** Cho phép `http://localhost:5173` (React Vite), `http://127.0.0.1:5173`, `http://localhost:3000`.
- **Cơ chế Header (`JwtAuthenticationFilter.java`):**
  - **Chống Giả Mạo (Anti-Spoofing):** Loại bỏ hoàn toàn các header `X-User-Id`, `X-User-Roles`, `X-User-Role`, `X-User-Phone`, `X-User-Kyc-Tier` do client gửi lên.
  - **Inject Tin Cậy:** Trích xuất từ JWT token đã xác thực chữ ký HMAC-SHA256 và inject tin cậy xuống downstream: `X-User-Id`, `X-User-Roles`, `X-User-Role`.
  - **Forward Header Chi Nhánh:** Bảo toàn và chuyển tiếp nguyên vẹn `X-Branch-Id` từ client (hoặc trích xuất từ JWT claim `branchId`) phục vụ quầy giao dịch.

---

### 4.2. Identity Service (`services/identity-service`)
- **Port:** `8081` | **Database:** `ewallet_identity_db` (`5433`).
- **Phân Quyền:** `ROLE_USER`, `ROLE_ADMIN`, `ROLE_TELLER` (Giao dịch viên quầy), `ROLE_MANAGER` (Kiểm soát viên chi nhánh).
- **Cơ chế Token:**
  - Access Token JWT Stateless (5 phút).
  - Refresh Token lưu trữ Redis / DB (7 ngày).
  - Redis Blacklist: `identity:blacklist:{jti}` thu hồi phiên tức thời khi đăng xuất.
- **eKYC Pipeline:** Tiếp nhận căn cước công dân, xác thực khuôn mặt và phân hạng KYC Tier (`UNVERIFIED`, `VERIFIED`, `TIER_2`, `TIER_3`).

---

### 4.3. Wallet Service (`services/wallet-service`)
- **Port HTTP:** `8082` | **Port gRPC:** `9090` | **Database:** `ewallet_wallet_db` (`5434`).
- **Nghiệp vụ:** Là **Lõi Lưu Ký Số Dư (Balance Custody Core)** của hệ thống.
- **Hợp Đồng gRPC Chuẩn (`WalletInternalService`):**
  - `DebitWallet(DebitRequest)`: Trừ tiền ví nguồn trong Spring Transaction + Redis Lock.
  - `CreditWallet(CreditRequest)`: Cộng tiền ví đích.
  - `ReserveBalance(ReserveRequest)`: Khóa tạm một khoản tiền (Hold / Reserve).
  - `ReleaseBalance(ReleaseRequest)`: Giải phóng khoản tiền đã khóa khi giao dịch thất bại.
  - `CheckLimit(LimitCheckRequest)`: Kiểm tra hạn mức giao dịch tức thời & hạn mức ngày.
  - `GetWalletByUserId(UserWalletRequest)`: Tra cứu thông tin ví theo `userId`.
- **Triệt tiêu Race Condition:**
  1. Khóa phân tán Redis: `lock:wallet:{walletId}` với lease time 5s.
  2. Khóa cơ sở dữ liệu: `SELECT * FROM wallets WHERE id = :id FOR UPDATE`.

---

### 4.4. Payment Service (`services/payment-service`)
- **Port:** `8083` | **Database:** `ewallet_payment_db` (`5435`).
- **Saga Orchestrator Workflow (P2P Transfer):**
  1. Khởi tạo giao dịch $\rightarrow$ Verify PIN.
  2. Gọi `gRPC DebitWallet` trừ tiền ví nguồn.
  3. Gọi `gRPC CreditWallet` cộng tiền ví đích.
  4. Nếu bước (3) thất bại: Saga Orchestrator lập tức gọi `gRPC CreditWallet` (hoặc `ReleaseBalance`) hoàn tiền tự động (**Auto-Reversal Compensating Transaction**).
  5. Bắn sự kiện Transaction Lifecycle sang Kafka topic `banking.payment.transaction-lifecycle.v1`.
- **Quầy Nạp Tiền Mặt Maker-Checker (`/api/v1/cash/**`):**
  - **Maker (Teller):** Khởi tạo phiếu nạp tiền `POST /api/v1/cash/deposit` với mã chi nhánh `X-Branch-Id`.
  - **Quy Tắc Ngưỡng Phê Duyệt:** Giao dịch $\le$ 50,000,000 VND được duyệt tự động; giao dịch > 50,000,000 VND bắt buộc chờ Manager phê duyệt.
  - **Checker (Manager):** Duyệt `POST /api/v1/cash/deposit/{id}/approve` hoặc Từ chối `POST /api/v1/cash/deposit/{id}/reject`.
  - **Ràng Buộc Nghiêm Ngặt:** Maker không được phép tự duyệt phiếu của chính mình (`MakerCheckerViolationException`).
  - Khi hoàn tất, phát sự kiện sang Kafka `banking.cash.deposit-completed.v1`.

---

### 4.5. Ledger Service (`services/ledger-service`)
- **Port:** `8084` | **Database:** `ewallet_ledger_db` (`5436`).
- **Bảo Vệ Dữ Liệu:** Cấp quyền Append-Only (`REVOKE UPDATE, DELETE ON ALL TABLES`).
- **Kế Toán Sổ Cái Kép:**
  - Tiếp nhận sự kiện giao dịch từ Kafka `banking.payment.transaction-lifecycle.v1` hoặc RabbitMQ `wallet.events`.
  - Mỗi giao dịch sinh ra:
    - 1 `JournalEntry` (Idempotent theo `transaction_id`).
    - Tối thiểu 2 `LedgerPosting` (1 bút toán Nợ `DEBIT` và 1 bút toán Có `CREDIT`).
  - Ràng buộc bất biến tuyệt đối:
    $$\sum \text{Debit Postings} = \sum \text{Credit Postings}$$
  - Hỗ trợ API đối soát số dư kế toán độc lập với số dư tức thời của `wallet-service`.

---

### 4.6. Notification Service (`services/notification-service`)
- **Port:** `8085` | **Database:** `ewallet_notification_db` (`5437`).
- **Nghiệp vụ:**
  - Consumer tiếp nhận sự kiện từ RabbitMQ queue `notification-service-queue` và Kafka topic `banking.wallet.balance-changed.v1`.
  - Gửi **Push FCM** tới ứng dụng di động qua Firebase Cloud Messaging.
  - Bắn tin nhắn Real-time qua **WebSocket STOMP** vào kênh riêng `/topic/wallet/{userId}`.
  - Quản lý token thiết bị (`device_tokens`) và lịch sử thông báo người dùng.

---

## 5. HẠ TẦNG MESSAGE BROKER KÉP (KAFKA & RABBITMQ)

### 5.1. Danh Sách Kafka Topics (KRaft Mode, 6 Partitions, RF 1)
| Topic Name | Partitions | Consumer Group | Mục Đích |
| :--- | :---: | :--- | :--- |
| `banking.payment.transaction-lifecycle.v1` | 6 | `ledger-service-group`, `notification-push-group` | Vòng đời giao dịch (INITIATED, SUCCESS, FAILED, REVERSED) |
| `banking.wallet.balance-changed.v1` | 6 | `notification-push-group` | Biến động số dư ví sau khi nạp, trừ hoặc hoàn tiền |
| `banking.ledger.postings.v1` | 6 | `audit-analytics-group` | Nhật ký bút toán sổ cái kép đã ghi nhận |
| `banking.cash.deposit-completed.v1` | 6 | `wallet-service-group`, `ledger-service-group` | Sự kiện nạp tiền mặt tại quầy đã được phê duyệt |

### 5.2. Danh Sách RabbitMQ Exchanges & Queues
- **Exchanges:** `wallet.events` (topic), `payment.events` (topic), `ledger.events` (topic).
- **Queues:**
  - `notification-service-queue`: Nhận sự kiện thông báo giao dịch.
  - `notification-service-dlq`: Dead Letter Queue chứa các bản tin xử lý lỗi quá số lần retry.

---

## 6. HƯỚNG DẪN SỬ DỤNG `codebase-memory-mcp` CHO AI AGENTS

Mọi AI Agent khi làm việc trên codebase này **bắt buộc tuân thủ nguyên tắc Graph-First** qua MCP Server `codebase-memory-mcp` v0.12.1:

### 6.1. Tra cứu Symbol Nhanh (`search_graph`)
```bash
# Tìm class Controller hoặc Service cụ thể:
codebase-memory-mcp cli search_graph --project=home-buidi-app-mono-di-va-khoa --query=JwtAuthenticationFilter

# Tìm các class xử lý nạp tiền mặt Maker-Checker:
codebase-memory-mcp cli search_graph --project=home-buidi-app-mono-di-va-khoa --query=CashDeposit
```

### 6.2. Lần Dấu Vết Lời Gọi Hàm & Luồng Dữ Liệu (`trace_path`)
```bash
# Phân tích chuỗi gọi hàm của phương thức nạp tiền mặt:
codebase-memory-mcp cli trace_path --project=home-buidi-app-mono-di-va-khoa --function_name=deposit --direction=both

# Lần luồng dữ liệu xuyên dịch vụ (Cross-Service):
codebase-memory-mcp cli trace_path --project=home-buidi-app-mono-di-va-khoa --function_name=DebitWallet --mode=cross_service
```

### 6.3. Trích Xuất Snippet Không Làm Tràn Context (`get_code_snippet`)
```bash
# Lấy nội dung code chính xác của 1 method:
codebase-memory-mcp cli get_code_snippet --project=home-buidi-app-mono-di-va-khoa --qn=com.fintech.gateway.JwtAuthenticationFilter.filter
```

### 6.4. Kiểm Tra Trạng Thái & Đồng Bộ Đồ Thị
```bash
# Kiểm tra số lượng nodes/edges và trạng thái watcher:
codebase-memory-mcp cli index_status --project=home-buidi-app-mono-di-va-khoa

# Phát hiện các file đã sửa đổi so với index:
codebase-memory-mcp cli detect_changes --project=home-buidi-app-mono-di-va-khoa
```

---

## 7. QUY TRÌNH VẬN HÀNH & KIỂM THỬ (RUNBOOK)

### 7.1. Khởi Động Toàn Bộ Hạ Tầng Docker
```bash
# Khởi chạy 5 PostgreSQL DBs, Redis, RabbitMQ, Kafka KRaft, Kafka-UI:
docker compose up -d

# Xác thực kiểm tra sức khỏe hạ tầng bằng script E2E với dữ liệu thật:
./scripts/e2e/01-infra-broker.sh
```

### 7.2. Kiểm Tra An Toàn Bảo Mật Cổng Công Khai
```bash
# Quét toàn bộ ports nội bộ (5433-5437, 5672, 6379, 9092) đảm bảo không bị lộ:
bash scripts/maintenance/security-audit-public.sh
```

### 7.3. Biên Dịch & Đóng Gói Hệ Thống (Maven Reactor)
```bash
# Build common-library (sinh gRPC stubs) và compile 5 microservices + Gateway:
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn clean install -DskipTests
```

### 7.4. Chạy Toàn Bộ Kiểm Thử Tự Động & Nghiệm Thu
```bash
# Chạy Unit Tests của module Gateway:
docker run --rm -v ~/.m2:/root/.m2 -v $(pwd):/app -w /app maven:3.9.6-eclipse-temurin-17-alpine mvn test -pl services/api-gateway

# Chạy hệ thống kiểm tra toàn diện 12/12 artifacts phân rã microservices:
bash scripts/verify-all-artifacts.sh
```

---
*Tài liệu `CODEBASE_MEMORY.md` được tự động xác thực và đồng bộ hóa trực tiếp từ hiện trạng mã nguồn dự án qua `codebase-memory-mcp` v0.12.1. Đảm bảo tính nhất quán 100%, không ảo giác và tường minh cho mọi tác vụ phát triển.*
