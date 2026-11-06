# Kiến Trúc Hệ Thống Microservices và Hạ Tầng Kỹ Thuật Sen Hồng Core Banking

## 1. Tổng quan Kiến trúc 6 Microservices Độc lập
Hệ thống Ngân hàng Số Sen Hồng (Sen Hồng Core Banking) được thiết kế theo kiến trúc Microservices phân tán hiện đại, áp dụng nguyên tắc Database-per-service (mỗi dịch vụ sở hữu cơ sở dữ liệu PostgreSQL riêng biệt, tuyệt đối không truy vấn chéo DB trực tiếp):

| Tên Dịch Vụ | Cổng (Port) | Cơ sở dữ liệu | Vai trò và Trách nhiệm Chính |
| :--- | :--- | :--- | :--- |
| **API Gateway** | `8080` (HTTP) | Redis (Blacklist) | Điểm vào duy nhất cho Client (Mobile, Web). Xác thực JWT Access Token, bộ lọc kiểm tra Redis Token Blacklist khi người dùng đăng xuất, Rate Limiting (chống DDOS), phân luồng định tuyến thông minh sang các dịch vụ nội bộ. |
| **Identity Service** | `8081` (HTTP) | Postgres `5433` (`identity_db`) | Quản lý vòng đời người dùng, đăng ký, đăng nhập Face ID / Mật khẩu, định danh eKYC, mã hóa mã PIN bằng thuật toán BCrypt độ phức tạp 12 (strength 12), tạo OTP lưu Redis TTL 5 phút, khóa tài khoản sau 5 lần nhập sai mã PIN hoặc mật khẩu, quản lý phiên và thiết bị đăng nhập. |
| **Wallet Service** | `8082` (HTTP) & `9090` (gRPC) | Postgres `5434` (`wallet_db`) | Quản lý số dư tài khoản khả dụng, hạn mức giao dịch theo ngày, nguồn tiền thanh toán. Sử dụng cơ chế Khóa bi quan (**Pessimistic Locking `SELECT ... FOR UPDATE`**) để chống tuyệt đối tình trạng chạy đua số dư (Race Condition) và số dư âm. Phát sinh sự kiện thay đổi số dư lên Apache Kafka topic `banking.wallet.balance-changed.v1`. Cung cấp cổng giao tiếp nội bộ gRPC port `9090` tốc độ cực cao cho Payment Service gọi trực tiếp. |
| **Payment Service** | `8083` (HTTP) | Postgres `5435` (`payment_db`) | Động cơ điều phối giao dịch trung tâm. Tích hợp **Saga Orchestrator (`PaymentSagaOrchestrator`)** cho luồng chuyển tiền P2P nguyên tử: `RESERVE_BALANCE` -> `DEBIT_WALLET` -> `CREDIT_WALLET`, tự động kích hoạt Compensating Action (hoàn tiền) nếu ngân hàng thụ hưởng phản hồi lỗi. Tích hợp mẫu thiết kế **Transactional Outbox Relay** đảm bảo At-least-once Delivery qua cả RabbitMQ (nhiệm vụ tác vụ) và Kafka (luồng sự kiện). Quản lý nạp tiền, rút tiền, thanh toán hóa đơn EVN/Nước, mở sổ tiết kiệm, giải ngân vay tiêu dùng Quick Loan, phát hành thẻ ảo Visa. |
| **Ledger Service** | `8084` (HTTP) | Postgres `5436` (`ledger_db`) | Hệ thống sổ cái kế toán kép chuẩn quốc tế (**Double-entry General Ledger**). Mọi biến động tài chính đều sinh cặp bản ghi bất biến `JournalEntry` (trạng thái POSTED) và tối thiểu 2 bút toán `LedgerPosting` (Tổng NỢ = Tổng CÓ, DEBIT = CREDIT). Nếu tổng phát sinh lệch ≠ 0, hệ thống tự động ngắt và kích hoạt ngoại lệ `LedgerUnbalancedException`. Sử dụng cơ chế Idempotency chống ghi trùng bút toán trọn đời. |
| **Notification Service** | `8085` (HTTP) | Postgres `5437` (`notification_db`) | Trung tâm thông báo đa kênh. Đẩy thông báo thời gian thực đến điện thoại khách hàng qua kết nối STOMP WebSocket (`/ws-native`, kênh `/topic/wallets/{id}/notifications`), đẩy thông báo nền qua Firebase Cloud Messaging (FCM) và định dạng SMS Banking. Độ trễ phát thông báo < 100ms. |
| **Chatbot Service** | `8000` (HTTP) | Postgres `5438` (`ewallet_chatbot_db` + pgvector) | Trợ lý tài chính thông minh 24/7 kiến trúc Dual-System (Jev System One gác cổng phân loại ý định và bảo mật zero-PII leak < 10ms; System Two Gemini RAG Hybrid Search kết hợp pgvector Cosine Distance và PostgreSQL tsvector RRF). |

---

## 2. Các Cơ chế An toàn Tài chính & Quy chuẩn Kỹ thuật Cốt lõi

### 1. Luồng Chuyển tiền P2P Saga Orchestrator (Nguyên tử & Chống Thất thoát)
- Khi khách hàng Alice chuyển tiền cho Bob:
  - **Bước 1 (Payment Service):** Kiểm tra tính hợp lệ của giao dịch, ghi nhận bản ghi giao dịch ở trạng thái `PENDING` và ghi sự kiện vào bảng `outbox_events` trong cùng một Database Transaction.
  - **Bước 2 (Giao tiếp gRPC sang Wallet Service):** Khóa bản ghi ví nguồn của Alice bằng `PESSIMISTIC_WRITE` (`SELECT ... FOR UPDATE`), kiểm tra số dư khả dụng và hạn mức ngày. Nếu đủ, trừ tiền ví nguồn (Debit Alice) và sinh giao dịch ví.
  - **Bước 3 (Credit Bob):** Cộng tiền vào ví đích của Bob. Nếu bước này gặp sự cố (ví dụ tài khoản Bob bị khóa hoặc ngân hàng đích từ chối), Saga Orchestrator ngay lập tức kích hoạt bước hoàn tiền bồi hoàn (**Compensating Action**), cộng lại tiền nguyên vẹn cho Alice và cập nhật trạng thái `REVERSED`.
  - **Bước 4 (Outbox Relay):** Luồng nền quét bảng `outbox_events` mỗi 500ms, đẩy song song lên Kafka topic `banking.payment.transaction-lifecycle.v1` và RabbitMQ exchange `wallet.transaction.events`.

### 2. Sổ Cái Kép Bất Biến (Double-Entry Ledger Integrity)
- Không có bất kỳ khoản tiền nào tự sinh ra hoặc tự mất đi:
  - Mỗi giao dịch chuyển tiền gồm:
    - Bút toán NỢ (DEBIT) tài khoản ví gửi: Phản ánh giảm nghĩa vụ nợ của ngân hàng đối với khách hàng gửi.
    - Bút toán CÓ (CREDIT) tài khoản ví nhận: Phản ánh tăng nghĩa vụ nợ đối với khách hàng nhận.
  - Nạp tiền từ ngân hàng liên kết:
    - Bút toán NỢ (DEBIT) tài khoản Nostro/Tiền gửi tại ngân hàng đối tác (Tài sản tăng).
    - Bút toán CÓ (CREDIT) tài khoản ví khách hàng (Nghĩa vụ nợ tăng).
  - Bảng ghi sổ cái là `APPEND-ONLY` (chỉ ghi thêm, không bao giờ UPDATE hay DELETE). Mọi điều chỉnh kế toán đều phải thực hiện bằng bút toán đảo ngược (Reversal Entry) để phục vụ kiểm toán độc lập và Ngân hàng Nhà nước.

### 3. Tiêu chuẩn Bảo mật Thông tin và Tuân thủ Pháp lý
- **Quyết định 2345/QĐ-NHNN:**
  - Giao dịch dưới 10.000.000 VNĐ: Xác thực bằng mã PIN 6 số hoặc Sinh trắc học thiết bị (Vân tay / Face ID).
  - Giao dịch từ 10.000.000 VNĐ trở lên hoặc tổng giá trị giao dịch trong ngày vượt quá 20.000.000 VNĐ: Bắt buộc xác thực khuôn mặt sinh trắc học đối chiếu với dữ liệu chip NFC trên Căn cước công dân gắn chip.
- **Bảo vệ Dữ liệu Định danh Cá nhân (Zero-PII Data Leak):**
  - Mọi câu hỏi của khách hàng chứa số thẻ, số tài khoản, số điện thoại, CCCD đều được đi qua bộ chuyển đổi Token bảo mật hai chiều (**Reversible PII Tokenizer**) trước khi phân tích. Dữ liệu tài chính nhạy cảm tuyệt đối không bao giờ bị rò rỉ ra các mô hình trí tuệ nhân tạo công cộng.
- **Tiền tệ và Số học chính xác:**
  - 100% các phép tính tiền tệ trong toàn bộ hệ sinh thái Microservices đều sử dụng kiểu dữ liệu `BigDecimal` (Java) và `numeric` (PostgreSQL), tuyệt đối không sử dụng kiểu dấu phẩy động `float`/`double` để ngăn chặn triệt để lỗi làm tròn sai lệch đồng xu.

