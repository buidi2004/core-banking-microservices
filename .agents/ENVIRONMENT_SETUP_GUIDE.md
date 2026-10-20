# 🛠️ AI Agent Environment Setup Guide (Backend, Frontend & Mobile)

> [!IMPORTANT]
> **DÀNH CHO TẤT CẢ CÁC AI AGENT KHI TIẾP QUẢN HOẶC KHỞI TẠO MÔI TRƯỜNG DỰ ÁN:**
> Tài liệu này cung cấp quy trình chuẩn từng bước (step-by-step checklist) để AI Agent tự động kiểm tra, tải dependencies, cấu hình môi trường và khởi chạy thành công toàn bộ 3 phân vùng của dự án:
> 1. **Hạ tầng & Backend Microservices (Java 17 / Spring Boot 3 / Docker Compose)**
> 2. **Frontend Web Portal (React 18 / Vite / TailwindCSS)**
> 3. **Mobile Client - Sen Hồng Bank (Flutter 3 / Clean Architecture / Liquid Glass)**

---

## 📋 1. Ma Trận Công Cụ & Yêu Cầu Phiên Bản (Prerequisites)

Trước khi thực thi bất kỳ lệnh nào, AI Agent cần chạy kiểm tra phiên bản công cụ trên máy host:

```bash
# Kiểm tra các công cụ cốt lõi
docker --version             # Yêu cầu: Docker Engine 24.0+
docker compose version       # Yêu cầu: Docker Compose v2.20+
java -version                # Yêu cầu: OpenJDK 17 hoặc Oracle JDK 17
mvn -version                 # Yêu cầu: Apache Maven 3.8+ (khuyên dùng 3.9+)
flutter --version            # Yêu cầu: Flutter 3.19+ (Dart 3.3+)
node -v                      # Yêu cầu: Node.js 18.x hoặc 20.x LTS
npm -v                       # Yêu cầu: npm 9.x+
adb version                  # Yêu cầu: Android Debug Bridge (nếu chạy Mobile trên thiết bị/máy ảo)
```

---

## 🐳 2. Khởi Động Cụm Hạ Tầng (Infrastructure Layer)

Dự án áp dụng kiến trúc **Database-per-Service** với 5 cơ sở dữ liệu PostgreSQL độc lập, 1 cụm Redis, 1 broker RabbitMQ và 1 cụm Apache Kafka (KRaft mode).

### Bước 2.1: Khởi động Containers Hạ tầng
```bash
# Từ thư mục gốc dự án (/home/buidi/core-banking-microservices)
docker compose up -d postgres-identity postgres-wallet postgres-payment postgres-ledger postgres-notification redis rabbitmq kafka kafka-ui
```

### Bước 2.2: Kiểm tra trạng thái sẵn sàng (Healthcheck)
AI Agent cần xác nhận tất cả 10 containers hạ tầng đều ở trạng thái `healthy` hoặc `Up`:
```bash
docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
```

**Bảng Cổng và Thông Tin Đăng Nhập Hạ Tầng:**
| Dịch Vụ | Container Name | Cổng Host | User / DB | Mật Khẩu |
| :--- | :--- | :---: | :--- | :--- |
| **Postgres Identity** | `ewallet-postgres-identity` | `5433:5432` | `identity_db_user` / `ewallet_identity_db` | `IdentityDb#Secure2025!` |
| **Postgres Wallet** | `ewallet-postgres-wallet` | `5434:5432` | `wallet_db_user` / `ewallet_wallet_db` | `WalletDb#Secure2025!` |
| **Postgres Payment** | `ewallet-postgres-payment` | `5435:5432` | `payment_db_user` / `ewallet_payment_db` | `PaymentDb#Secure2025!` |
| **Postgres Ledger** | `ewallet-postgres-ledger` | `5436:5432` | `ledger_app_user` / `ewallet_ledger_db` | `LedgerApp#Secure2025!` |
| **Postgres Notification**| `ewallet-postgres-notification` | `5437:5432` | `notification_db_user` / `ewallet_notification_db`| `NotificationDb#Secure2025!` |
| **Redis** | `ewallet-redis` | `6379:6379` | — | *(Không mật khẩu)* |
| **RabbitMQ** | `ewallet-rabbitmq` | `5672`, `15672` | `wallet` | `wallet123` |
| **Apache Kafka** | `ewallet-kafka` | `9092`, `29092`| Broker KRaft | PLAINTEXT |
| **Kafka UI** | `ewallet-kafka-ui` | `8090:8080` | Quản trị Kafka | *(Mở trên trình duyệt)* |

---

## ⚙️ 3. Thiết Lập & Khởi Chạy Backend Microservices

Backend bao gồm 6 dịch vụ Spring Boot 3 và 1 thư viện dùng chung `common-library` (chứa Protobuf stubs).

### Bước 3.1: Biên dịch `common-library` trước (BẮT BUỘC)
> [!IMPORTANT]
> `common-library` tạo ra mã nguồn gRPC stubs từ `src/main/proto/wallet.proto`. Nếu không biên dịch thư viện này trước, `wallet-service` và `payment-service` sẽ báo lỗi thiếu class gRPC (`WalletServiceGrpc`).
```bash
mvn -f backend/common-library/pom.xml clean install -DskipTests
```

### Bước 3.2: Biên dịch toàn bộ các Microservices
```bash
mvn -f backend/pom.xml clean compile -DskipTests
```

### Bước 3.3: Lựa chọn cách khởi chạy Backend

#### Cách 1: Chạy toàn bộ qua Docker (Khuyên dùng khi kiểm thử tích hợp)
```bash
# Build và chạy 6 microservices: api-gateway, identity, wallet, payment, ledger, notification
docker compose up -d --build api-gateway identity-service wallet-service payment-service ledger-service notification-service
```

#### Cách 2: Chạy qua bộ điều khiển CLI tổng thể
```bash
./run.sh be
```

#### Cách 3: Chạy cục bộ từng Microservice (Dành cho việc debug chi tiết)
Mở terminal riêng cho từng dịch vụ và chạy lệnh Maven Spring Boot:
```bash
# 1. API Gateway (Cửa ngõ: 8080)
mvn -f backend/services/api-gateway/pom.xml spring-boot:run

# 2. Identity Service (Port: 8081)
mvn -f backend/services/identity-service/pom.xml spring-boot:run

# 3. Wallet Service (HTTP: 8082, gRPC: 9090)
mvn -f backend/services/wallet-service/pom.xml spring-boot:run

# 4. Payment Service (Port: 8083)
mvn -f backend/services/payment-service/pom.xml spring-boot:run

# 5. Ledger Service (Port: 8084)
mvn -f backend/services/ledger-service/pom.xml spring-boot:run

# 6. Notification Service (Port: 8085 / WS: 8080)
mvn -f backend/services/notification-service/pom.xml spring-boot:run
```

---

## 💻 4. Thiết Lập & Khởi Chạy Frontend Web Portal (React Vite)

Cổng dành cho cán bộ quầy (Teller) phê duyệt nạp tiền mặt Maker-Checker và giám sát hạn mức két quỹ chi nhánh.

### Bước 4.1: Cài đặt Node modules
```bash
cd frontend/cash-deposit-portal
npm install
```

### Bước 4.2: Khởi chạy Dev Server
```bash
# Khởi chạy Vite server (Mặc định Port: 5173)
npm run dev
```
- **Địa chỉ truy cập Web:** `http://localhost:5173`
- **Tài khoản mặc định:**
  - Giao dịch viên (Teller): `teller1` / `Password123!`
  - Kiểm soát viên (Manager): `manager1` / `Password123!`

---

## 📱 5. Thiết Lập & Khởi Chạy Mobile App - Sen Hồng Bank (Flutter)

Ứng dụng di động xây dựng bằng Flutter Clean Architecture và Liquid Glass UI.

### Bước 5.1: Cài đặt Flutter Dependencies
```bash
cd mobile
flutter pub get
```

### Bước 5.2: Kiểm tra tính toàn vẹn mã nguồn
```bash
flutter analyze
```

### Bước 5.3: Cấu hình cầu nối mạng (ADB Reverse) cho thiết bị thật
> [!TIP]
> Để ứng dụng trên điện thoại Android thật có thể gọi được API Gateway tại `http://localhost:8080`, AI Agent cần đảm bảo lệnh sau được thực thi khi kết nối cáp USB:
```bash
adb reverse tcp:8080 tcp:8080
```
*(Nếu sử dụng script `./mobile/run.sh run`, bước này được tự động hóa hoàn toàn).*

### Bước 5.4: Khởi chạy ứng dụng
```bash
# Chạy trên thiết bị di động kết nối hoặc máy ảo Android/iOS:
cd mobile
./run.sh run
# Hoặc: flutter run

# Hoặc chạy trên trình duyệt Web để xem nhanh giao diện:
flutter run -d chrome
```

---

## 🧪 6. Quy Trình Kiểm Thử & Xác Nhận Hệ Thống (Verification Checklist)

Mọi AI Agent sau khi cài đặt môi trường **BẮT BUỘC** phải chạy 3 bài kiểm tra sau để xác nhận hệ thống hoạt động 100%:

### 1. Kiểm tra Backend Unit & Concurrency Tests:
```bash
# Kiểm thử toàn diện ví và khóa bi quan (27 tests)
mvn -f backend/services/wallet-service/pom.xml test

# Kiểm thử Saga & Outbox Relay (3 tests)
mvn -f backend/services/payment-service/pom.xml test
```
*Kỳ vọng: Tất cả test suites đều trả về `BUILD SUCCESS` (0 failures, 0 errors).*

### 2. Kiểm tra Mobile QA Test Suite:
```bash
cd mobile
flutter test test/qa_commits_review_test.dart
```
*Kỳ vọng: `All tests passed! (6/6 tests)`.*

### 3. Kiểm thử Toàn trình E2E (9 Bước Dữ Liệu Thật):
```bash
bash scratch/test_e2e_baseline.sh
```
*Kỳ vọng: Toàn bộ 9 bước đăng ký, nạp tiền, chuyển tiền P2P Saga, cân bằng sổ cái kép Ledger và bắn thông báo Notification hoàn tất không có lỗi.*

---

## 🚨 7. Cẩm Nang Xử Lý Sự Cố Cho AI Agent (Troubleshooting)

| Vấn Đề Gặp Phải | Nguyên Nhân | Cách Khắc Phục Chuẩn |
| :--- | :--- | :--- |
| **Lỗi biên dịch thiếu class `WalletServiceGrpc`** | Chưa biên dịch thư viện Protobuf `common-library`. | Chạy: `mvn -f backend/common-library/pom.xml clean install -DskipTests`. |
| **Xung đột cổng 5432 trên máy host** | Máy host đang chạy PostgreSQL local. | Dự án đã đổi cổng host sang `5433 - 5437`. Không cần tắt Postgres local. |
| **Mobile báo lỗi mất mạng / Timeout khi gọi API** | Chưa map cổng API Gateway vào thiết bị di động. | Chạy: `adb reverse tcp:8080 tcp:8080`. |
| **Testcontainers báo lỗi client version** | Testcontainers kén phiên bản Docker daemon. | Các unit test đã tách biệt độc lập; chạy với `mvn test -Dtest=WalletGrpcServiceTest,WalletConcurrencyTest...`. |
| **RabbitMQ phình tin nhắn không có ai nhận** | Queue bị cấu hình sai binding routing key. | Đảm bảo exchange là `wallet.transaction.events` (Topic) và queue bind `transaction.#`. |

