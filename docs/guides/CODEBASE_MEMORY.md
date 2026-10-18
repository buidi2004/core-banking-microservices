# 🧠 CODEBASE MEMORY: CORE BANKING MICROSERVICES BLUEPRINT
### Hệ Thống Ngân Hàng Lõi Đạt Chuẩn Kiến Trúc Database-per-Service & Sổ Cái Kép

> **Tài liệu tham chiếu chuẩn cho AI Coding Agents, Kỹ sư Phần mềm và Hội đồng Kiến trúc.**  
> **Động cơ phân tích mã nguồn:** `codebase-memory-mcp` v0.12.1 (Tree-sitter AST Knowledge Graph).  
> **Chỉ số đồ thị thực tế:** **`14,522 nodes` | `61,442 edges`** (Repository: `buidi2004/core-banking-microservices`).  
> **Kiến trúc:** `Database-per-Service Microservices + Hexagonal DDD + Saga Pattern + gRPC Core + Event-Driven (EDA)`.  
> **Trạng thái:** `Production Ready | Monorepo Structure | Dual-Run Reference Validated`.

---

## 1. TỔNG QUAN KIẾN TRÚC & QUY MÔ HỆ THỐNG

Hệ thống **Core Banking Microservices** là giải pháp ngân hàng lõi & ví điện tử phân tán, được thiết kế theo tiêu chuẩn công nghiệp tài chính với nguyên tắc **Database-per-Service**, độc lập hoàn toàn về cơ sở dữ liệu, nghiệp vụ và chu kỳ triển khai giữa các dịch vụ:

- **Nền tảng công nghệ:** Java 17, Spring Boot 3.2.5, Spring Cloud Gateway.
- **Giao tiếp liên dịch vụ:**
  - **Đồng bộ siêu tốc:** High-performance gRPC (Protocol Buffers v3) giữa `payment-service` và `wallet-service` (Port 9090).
  - **Bất đồng bộ tin cậy:** RabbitMQ (Topic Exchanges & Dead Letter Queues) kết hợp **Transactional Outbox Pattern**.
  - **Cửa ngõ tập trung:** Spring Cloud Gateway (Port 8080) với cơ chế định tuyến, xác thực JWT Relay và Rate Limiting.
- **Tính nhất quán dữ liệu phân tán:**
  - Triển khai **Saga Orchestrator Pattern** với cơ chế tự động bù trừ (Auto-Reversal / Compensating Transactions).
  - Loại bỏ hoàn toàn Race Condition nhờ cơ chế khóa 2 tầng: **Redis Distributed Lock** + **PostgreSQL Pessimistic Lock (`SELECT ... FOR UPDATE`)**.
- **Kế toán tài chính bất biến:**
  - Hạch toán **Sổ cái kép (Double-Entry Bookkeeping)** độc lập tại `ledger-service`.
  - Mọi giao dịch biến động số dư bắt buộc cân bằng tuyệt đối: $\sum \text{Debit} = \sum \text{Credit}$.

```
                                  [ INTERNET CLIENTS ]
                               (Mobile App / Web SPA / Postman)
                                              |
                                              v
                              +-------------------------------+
                              |    API GATEWAY (Port 8080)    |
                              |   Spring Cloud Gateway / JWT  |
                              +---------------+---------------+
                                              |
      +-------------------+-------------------+-------------------+-------------------+
      | (Port 8081)       | (Port 8082)       | (Port 8083)       | (Port 8084)       | (Port 8085)
      v                   v                   v                   v                   v
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
|  IDENTITY   |     |   WALLET    |     |   PAYMENT   |     |   LEDGER    |     |NOTIFICATION |
|   SERVICE   |     |   SERVICE   |     |   SERVICE   |     |   SERVICE   |     |   SERVICE   |
| (Auth, eKYC)|     | (Lõi Ví,PIN)|     | (Saga P2P,  |     | (Sổ cái kép,|     | (FCM Push,  |
|             |     |  gRPC: 9090 |<----+  VietQR)    |     |  Bút toán)  |     |  STOMP WS)  |
+------+------+     +------+------+     +------+------+     +------+------+     +------+------+
       |                   |                   |                   |                   |
       |                   | (Events)          | (Outbox Events)   | (Consumes)        | (Consumes)
       |                   +---------+   +-----+---------+   +-----+-----+             |
       |                             |   |               |   |           |             |
       |                             v   v               v   v           v             v
       |                     +---------------------------------------------------------------+
       |                     |             RABBITMQ EVENT BUS (Port 5672)                    |
       |                     | Exchanges: wallet.events, payment.events, ledger.events       |
       |                     +---------------------------------------------------------------+
       |
       v (Database-per-Service: Mỗi service sở hữu DB riêng biệt, không chia sẻ)
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

## 2. BẢN ĐỒ CẤU TRÚC THƯ MỤC MONOREPO

Cấu trúc dự án được chuẩn hóa theo chuẩn công nghiệp Monorepo:

```
core-banking-microservices/
├── .agents/                                  # Cấu hình AI Agents & MCP Servers
│   ├── mcp_config.json                       # Khai báo codebase-memory-mcp & postgres MCP
│   └── skills/archify/                       # Skill tạo sơ đồ kiến trúc tương tác
│
├── common-library/                           # Thư viện dùng chung (Shared Kernel)
│   ├── src/main/proto/wallet.proto           # Định nghĩa Protobuf gRPC Stubs (Lock/Credit/Deduct)
│   └── src/main/java/com/fintech/wallet/     # Common DTOs, Event Models, Utility classes
│
├── services/                                 # CÁC DỊCH VỤ MICROSERVICES ĐỘC LẬP
│   ├── api-gateway/                          # [Port 8080] Central Gateway, JWT Relay, Routing
│   ├── identity-service/                     # [Port 8081] Auth, Token 5m, eKYC, Users (DB: 5433)
│   ├── wallet-service/                       # [Port 8082, gRPC 9090] Core Wallet, Redis Lock (DB: 5434)
│   ├── payment-service/                      # [Port 8083] Saga Orchestrator, VietQR, P2P (DB: 5435)
│   ├── ledger-service/                       # [Port 8084] Double-Entry Ledger, Append-Only (DB: 5436)
│   └── notification-service/                 # [Port 8085] Push Firebase FCM, WebSocket STOMP (DB: 5437)
│
├── legacy/                                   # BẢO TỒN BẢN MONOLITH ĐỐI SOÁT DUAL-RUN
│   └── monolith/                             # Mã nguồn nguyên bản 100% làm reference & load test
│
├── docs/                                     # TÀI LIỆU KỸ THUẬT & KIẾN TRÚC
│   ├── architecture/                         # Báo cáo chuyển đổi, sơ đồ kiến trúc, Saga spec
│   └── guides/                               # Hướng dẫn chi tiết: CODEBASE_MEMORY, Frontend Dev
│
├── scripts/                                  # SCRIPTS VẬN HÀNH & KIỂM THỬ
│   ├── verify-all-artifacts.sh               # Kịch bản kiểm thử tích hợp 12/12 artifacts
│   └── maintenance/                          # Công cụ cập nhật & bảo trì dữ liệu
│
├── docker-compose.yml                        # Khởi chạy 5 Microservices + 5 DBs + Redis + RabbitMQ
├── docker-compose.legacy.yml                 # Khởi chạy hạ tầng cho cụm Monolith đối chiếu
└── pom.xml                                   # Root Maven Reactor Quản lý Multi-Module
```

---

## 3. THỐNG KÊ ĐỒ THỊ MÃ NGUỒN TỪ `codebase-memory-mcp`

Dữ liệu được trích xuất trực tiếp thông qua engine `codebase-memory-mcp` v0.12.1 với engine phân tích AST Tree-sitter:

### 3.1. Chỉ số Graph Tổng thể
- **Project Name:** `home-buidi-app-mono-di-va-khoa`
- **Total Nodes:** **`14,522 nodes`**
- **Total Edges:** **`61,442 edges`**
- **Trạng thái Index:** `READY` (RAM-first SQLite Graph + LZ4 Compression)
- **Tập tin được lập chỉ mục:** 623 files (568 Java, 24 SQL Migrations, 21 YAML Configs, 9 HTML, 1 Shell)

### 3.2. Phân Bổ Nodes Theo Package & Module
| Phân hệ / Thư mục | Số Nodes | Vai trò chính |
|:---|:---:|:---|
| `skills/archify` | **3,425** | Hệ thống công cụ tự động hóa sơ đồ kiến trúc |
| `legacy/monolith` | **2,661** | Bản Monolith đối chứng phục vụ Dual-Run và Audit |
| `architecture/docs` | **751** | Tài liệu kiến trúc và đặc tả kiểm thử |
| `services/notification-service` | **415** | Xử lý push FCM, WebSocket STOMP và RabbitMQ Consumer |
| `services/wallet-service` | **345** | Quản lý số dư, Pessimistic Lock, gRPC Server Port 9090 |
| `services/ledger-service` | **304** | Ghi sổ kế toán kép, kiểm tra bất biến nợ/có |
| `services/payment-service` | **192** | Saga Coordinator, P2P Transfer, VietQR EMVCo |
| `services/identity-service` | **140** | Xác thực JWT, User Profile, eKYC, Quản lý phiên |
| `services/api-gateway` | **43** | Spring Cloud Gateway routes, Filters & Cors |

### 3.3. Các Kiểu Mối Quan Hệ (Graph Edge Types)
- **`CALLS`:** Truy vết toàn diện mọi lời gọi hàm giữa Controller -> Service -> Port -> Adapter.
- **`IMPLEMENTS`:** Ánh xạ từ Port Interface (Domain) sang JPA / Redis / RabbitMQ Adapter.
- **`IMPORTS` / `DEFINES`:** Theo dõi sự phụ thuộc giữa các package và class.
- **`HAS_MEMBER` / `HAS_PARAMETER`:** Đặc tả chi tiết thuộc tính, tham số và giá trị trả về của từng phương thức.

---

## 4. CHI TIẾT KỸ THUẬT CÁC MICROSERVICES LÕI

### 4.1. Identity Service (`services/identity-service`)
- **Cổng giao tiếp:** HTTP REST (`8081`) | **Database:** `identity_db` (`5433`).
- **Nghiệp vụ trọng tâm:**
  - Cung cấp cơ chế xác thực JWT Stateless với thời gian sống ngắn (**5 phút**) + Refresh Token (7 ngày).
  - Băm mật khẩu và mã PIN thanh toán bằng thuật toán bảo mật `BCryptPasswordEncoder`.
  - Quản lý phiên làm việc đa thiết bị (`user_sessions`), hỗ trợ đăng xuất đơn lẻ hoặc thu hồi phiên toàn bộ thiết bị từ xa qua Redis Token Blacklist.
  - Quy trình duyệt hồ sơ định danh điện tử **eKYC** tích hợp OCR và Face Matching.
- **REST Endpoints chính:**
  - `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`
  - `POST /api/v1/kyc/submit`, `GET /api/v1/kyc/status`
  - `GET /api/v1/users/me`, `PUT /api/v1/users/profile`

### 4.2. Wallet Service (`services/wallet-service`)
- **Cổng giao tiếp:** HTTP REST (`8082`), **gRPC Server (`9090`)** | **Database:** `wallet_db` (`5434`).
- **Nghiệp vụ trọng tâm:**
  - Đóng vai trò là **Lõi bảo vệ số dư (Balance Custody Core)** của toàn bộ ngân hàng.
  - Khóa số dư 2 tầng triệt tiêu hoàn toàn Race Condition:
    1. **Redis Distributed Lock:** `lock:wallet:{walletId}` với TTL tự hủy.
    2. **Database Pessimistic Lock:** `SELECT ... FOR UPDATE` trong Spring Transaction.
  - Cung cấp **gRPC Endpoint** cho các service khác gọi trực tiếp với độ trễ siêu thấp:
    - `LockFunds(wallet_id, amount, idempotency_key)`
    - `DeductFunds(wallet_id, amount, transaction_id)`
    - `CreditFunds(wallet_id, amount, transaction_id)`
    - `ReleaseFunds(wallet_id, amount, idempotency_key)`
  - Kiểm soát hạn mức giao dịch nghiêm ngặt: 1,000 VND - 50,000,000 VND/giao dịch; hạn mức ngày 100,000,000 VND (chưa KYC: 5,000,000 VND).

### 4.3. Payment Service (`services/payment-service`)
- **Cổng giao tiếp:** HTTP REST (`8083`) | **Database:** `payment_db` (`5435`).
- **Nghiệp vụ trọng tâm:**
  - Đóng vai trò **Saga Orchestrator** cho các luồng giao dịch phân tán:
    - **P2P Transfer Flow:** `Khởi tạo` $\rightarrow$ `Verify PIN` $\rightarrow$ `gRPC Lock Funds Ví Nguồn` $\rightarrow$ `gRPC Credit Funds Ví Đích` $\rightarrow$ `Phát Event Outbox Sang Ledger & Notification` $\rightarrow$ `Hoàn tất`.
    - **Auto-Reversal (Compensating Flow):** Nếu bước Credit thất bại hoặc timeout, Saga Orchestrator tự động gọi `gRPC ReleaseFunds` hoàn tiền về ví nguồn và đánh dấu trạng thái giao dịch là `REVERSED`.
  - Sinh và giải mã chuẩn thanh toán **VietQR / EMVCo** (TLV format, mã checksum CRC-16 Tag 63).
  - Quản lý yêu cầu chuyển tiền & chia hóa đơn (Money Request & Split Bill).

### 4.4. Ledger Service (`services/ledger-service`)
- **Cổng giao tiếp:** HTTP REST (`8084`), RabbitMQ Consumer | **Database:** `ledger_db` (`5436`).
- **Nghiệp vụ trọng tâm:**
  - Lưu trữ **Sổ cái kế toán kép bất biến (Immutable Double-Entry Ledger)**.
  - Tiếp nhận sự kiện `TransactionCompletedEvent` từ RabbitMQ Topic Exchange `wallet.events`.
  - Mỗi giao dịch sinh ra:
    - 1 `JournalEntry` (Idempotent theo `transaction_id`).
    - Tối thiểu 2 `LedgerPosting` (1 bút toán Nợ DEBIT và 1 bút toán Có CREDIT).
  - Ràng buộc cân bằng tài chính tuyệt đối:
    $$\sum \text{Debit Postings} = \sum \text{Credit Postings}$$
  - Hỗ trợ API đối soát số dư kế toán độc lập với số dư tức thời của `wallet-service`.

### 4.5. Notification Service (`services/notification-service`)
- **Cổng giao tiếp:** HTTP REST (`8085`), WebSocket (`ws://...`) | **Database:** `notification_db` (`5437`).
- **Nghiệp vụ trọng tâm:**
  - Tiếp nhận sự kiện biến động số dư qua RabbitMQ.
  - Gửi **Push Notification** đa kênh:
    - **Google Firebase Cloud Messaging (FCM):** Đẩy thông báo tức thì tới thiết bị di động (ngay cả khi ứng dụng đang đóng).
    - **WebSocket STOMP:** Bắn tin nhắn Real-time vào channel riêng của người dùng `/topic/wallet/{userId}`.
  - Quản lý token thiết bị (`device_tokens`) và lịch sử thông báo nhận được.

### 4.6. API Gateway (`services/api-gateway`)
- **Cổng giao tiếp:** HTTP Gateway (`8080`).
- **Nghiệp vụ trọng tâm:**
  - Điểm tiếp nhận request duy nhất từ bên ngoài.
  - Định tuyến thông minh theo tiền tố path:
    - `/api/v1/auth/**`, `/api/v1/users/**`, `/api/v1/kyc/**` $\rightarrow$ `identity-service:8081`
    - `/api/v1/wallets/**` $\rightarrow$ `wallet-service:8082`
    - `/api/v1/payments/**`, `/api/v1/transfers/**`, `/api/v1/qr/**` $\rightarrow$ `payment-service:8083`
    - `/api/v1/ledger/**` $\rightarrow$ `ledger-service:8084`
    - `/api/v1/notifications/**` $\rightarrow$ `notification-service:8085`
  - Tích hợp bộ lọc CORS, trích xuất Token JWT và chuyển tiếp `X-User-Id`, `X-User-Roles` xuống các service nội bộ.

---

## 5. HƯỚNG DẪN SỬ DỤNG `codebase-memory-mcp` DÀNH CHO AI AGENTS

Đồ thị mã nguồn được duy trì bởi công cụ `codebase-memory-mcp` v0.12.1. Tất cả AI Agents và lập trình viên phải sử dụng các lệnh dưới đây để định vị và phân tích mã nguồn thay vì tìm kiếm thủ công (grep):

### 5.1. Cấu Hình MCP Server
Đã được cấu hình tự động tại `.agents/mcp_config.json` và `~/.gemini/config/mcp_config.json`:
```json
{
  "mcpServers": {
    "codebase-memory-mcp": {
      "command": "/home/buidi/.local/bin/codebase-memory-mcp",
      "args": []
    }
  }
}
```

### 5.2. Các Lệnh CLI Tra Cứu Trực Tiếp (17 MCP Tools)

#### 1. Tra cứu Class / Interface / Service (`search_graph`):
```bash
# Tìm tất cả Controller trong các Microservices
codebase-memory-mcp cli search_graph '{"project": "home-buidi-app-mono-di-va-khoa", "name_pattern": ".*Controller.*", "label": "Class"}'

# Tìm phương thức khóa tiền gRPC trong Wallet Service
codebase-memory-mcp cli search_graph '{"project": "home-buidi-app-mono-di-va-khoa", "name_pattern": ".*LockFunds.*", "label": "Method"}'
```

#### 2. Truy vết cây gọi hàm & Blast Radius (`trace_call_path`):
```bash
# Phân tích toàn bộ phương thức gọi đến và được gọi bởi hàm transfer:
codebase-memory-mcp cli trace_call_path '{"project": "home-buidi-app-mono-di-va-khoa", "function_name": "home-buidi-app-mono-di-va-khoa.services.wallet-service.src.main.java.com.fintech.wallet.application.service.WalletService.transfer", "direction": "both"}'
```

#### 3. Trích xuất kiến trúc và tỷ lệ phụ thuộc (`get_architecture`):
```bash
codebase-memory-mcp cli get_architecture '{"project": "home-buidi-app-mono-di-va-khoa"}'
```

#### 4. Kiểm tra trạng thái đồ thị (`index_status`):
```bash
codebase-memory-mcp cli index_status '{"project": "home-buidi-app-mono-di-va-khoa"}'
```

#### 5. Quét và cập nhật đồ thị khi có thay đổi mã nguồn (`index_repository`):
```bash
codebase-memory-mcp cli index_repository '{"repo_path": "/home/buidi/app-mono-di-va-khoa"}'
```

---

## 6. HƯỚNG DẪN VẬN HÀNH & TRIỂN KHAI (RUNBOOK)

### 6.1. Khởi Động Hạ Tầng Phân Tán (Docker Compose)
Chạy toàn bộ 5 Databases PostgreSQL, Redis và RabbitMQ:
```bash
docker compose up -d
# Kiểm tra trạng thái:
# identity_db (5433), wallet_db (5434), payment_db (5435), ledger_db (5436), notification_db (5437)
# Redis (6379), RabbitMQ (5672, 15672)
```

### 6.2. Biên Dịch & Đóng Gói Toàn Bộ Hệ Thống (Maven Reactor)
Thực thi tại thư mục gốc của repository:
```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn clean install -DskipTests
```
Lệnh trên sẽ tự động build `common-library` (sinh Protobuf gRPC stubs), sau đó compile lần lượt cả 5 microservices và API Gateway.

### 6.3. Chạy Toàn Bộ Bộ Kiểm Thử Tự Động
```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn test
```
- **Kịch bản kiểm thử tích hợp:** `bash scripts/verify-all-artifacts.sh` (**12/12 PASSED 100%**).
- **Kiểm thử bất biến sổ cái kép:** Đảm bảo `LedgerServiceIntegrationTest` không có bất kỳ sai lệch nào về số dư.
- **Kiểm thử Saga Reversal:** Đảm bảo khi cổng thanh toán giả lập bị lỗi, tiền lập tức được hoàn trả về ví nguồn nguyên vẹn.

### 6.4. Chế Độ Dual-Run Đối Chiếu Với Bản Monolith
Khi thực hiện nâng cấp hoặc đối soát tải:
```bash
# Khởi chạy bản Monolith cũ để so sánh hành vi API:
docker compose -f docker-compose.legacy.yml up -d
cd legacy/monolith && mvn test
```

---
_Tài liệu `CODEBASE_MEMORY.md` được tự động quét, xác thực cấu trúc và đồng bộ hóa bởi `codebase-memory-mcp` v0.12.1. Đảm bảo phản ánh chính xác 100% hiện trạng mã nguồn của dự án Core Banking Microservices._
