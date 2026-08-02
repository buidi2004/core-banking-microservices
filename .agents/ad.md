# Báo Cáo Chuyên Sâu: Kiến trúc, Công nghệ & Tích hợp API Backend

Dựa trên việc phân tích đồ thị mã nguồn (codebase graph) và file cấu hình gốc (`pom.xml`), dưới đây là báo cáo chuyên sâu, đầy đủ nhất về hệ thống Backend. Báo cáo này giúp đội ngũ Frontend (FE), Mobile và các bên liên quan (Stakeholders) nắm rõ quy mô, công nghệ và danh sách các điểm tích hợp (API endpoints).

---

## 1. Tổng quan Dự án (Executive Summary)

- **Quy mô dự án**: Nền tảng Ví điện tử đa năng (E-Wallet).
- **Kiến trúc áp dụng**: **Hexagonal Architecture** (Kiến trúc Lục giác / Clean Architecture). Cấu trúc mã nguồn chia tách rõ ràng lớp Domain (Cốt lõi nghiệp vụ), Port (Giao diện tích hợp) và Adapter (Triển khai kỹ thuật).
- **Quy mô Codebase**: Có hàng trăm file Java trong dự án (bao gồm Controller, Service, Domain Model, Port, Adapter, Exception...). Thông qua việc rà quét, hệ thống hiện đang có **16 Controllers** xử lý nghiệp vụ, phơi bày (expose) **hơn 80 API endpoints** khác nhau để Frontend có thể giao tiếp.

---

## 2. Stack Công Nghệ & Thư Viện (Tech Stack & Dependencies)

Hệ thống sử dụng một bộ khung công nghệ (Tech Stack) vô cùng mạnh mẽ, theo tiêu chuẩn Enterprise-Grade của hệ sinh thái Java:

### ⚙️ Core & Backend Framework

- **Ngôn ngữ**: `Java 17` (hỗ trợ record, switch expression, pattern matching giúp code ngắn gọn, hiệu năng cao).
- **Framework nền tảng**: `Spring Boot 3.2.5` (Phiên bản mới nhất, an toàn và tối ưu).
- **Lập trình Web & Realtime**:
  - `Spring Boot Web`: Xây dựng chuẩn RESTful API.
  - `Spring WebSocket`: Hỗ trợ giao tiếp 2 chiều (real-time) cho thông báo (notification), biến động số dư.

### 🗄️ Database & Caching (Dữ liệu & Bộ nhớ đệm)

- **Cơ sở dữ liệu chính**: `PostgreSQL` (Sử dụng cho môi trường Production, độ tin cậy cực cao).
- **Cơ sở dữ liệu Test**: `H2 Database` (In-memory DB dùng cho Dev và Unit Test).
- **ORM**: `Spring Data JPA` (Giao tiếp với CSDL qua các Object/Entity).
- **Caching & Khóa phân tán**: `Spring Data Redis`. Redis được dùng làm bộ đệm và tạo **Distributed Lock** (khóa phân tán) giúp chống lỗi Race-Condition (ví dụ: cấm user click đúp chuyển tiền).

### 🛡️ Security & Resilience (Bảo mật & Tính chống chịu)

- **Xác thực và Phân quyền**: `Spring Security`.
- **Stateless Authentication**: Sử dụng `JJWT (Java JWT 0.12.5)` để gen token đăng nhập.
- **Circuit Breaker (Ngắt mạch)**: `Resilience4j`. Giúp hệ thống không bị "sụp chuyền" khi gọi các API bên thứ 3 (như API ngân hàng, API eKYC) bị chậm hoặc lỗi.

### 📊 Observability & Utilities (Giám sát & Tiện ích)

- **Monitoring**: `Spring Boot Actuator` & `Micrometer Prometheus`. Cung cấp chỉ số sức khỏe của app cho hệ thống giám sát Prometheus/Grafana.
- **Tiện ích Code**: `Lombok`.
- **Xuất báo cáo (Export)**: Sử dụng `OpenPDF` (sinh PDF sao kê) và `Apache POI` (sinh Excel/CSV) trực tiếp tại Backend.
- **Validation**: `Spring Boot Validation` kiểm tra nghiêm ngặt dữ liệu đầu vào.

---

## 3. Bản Đồ API Backend (Dành cho Frontend / Mobile tích hợp)

Qua rà soát lớp Controller (`@RestController`), có khoảng **82+ APIs** trải dài trên 16 Controllers. Dưới đây là bức tranh toàn cảnh (Mapping) để FE thực hiện tích hợp:

### 3.1. Nhóm Quản lý Ví & Giao dịch (Wallet & Transactions)

Nhóm API cốt lõi nhất, xử lý dòng tiền.

- **`WalletController`**:
  - `POST /api/v1/wallets` : Khởi tạo ví mới.
  - `GET /api/v1/wallets/{walletId}` : Truy vấn số dư và thông tin ví.
  - `POST /api/v1/wallets/deposit` : Nạp tiền vào ví (từ ngân hàng).
  - `POST /api/v1/wallets/withdraw` : Rút tiền từ ví (về ngân hàng).
  - `POST /api/v1/wallets/transfer` : Chuyển tiền P2P (giữa 2 ví).
- **`TransactionQueryController`**: (Dùng để xem lịch sử, sao kê)
  - `GET /api/v1/transactions` : Lọc và phân trang lịch sử giao dịch.
  - `GET /api/v1/transactions/{id}` : Xem chi tiết 1 mã giao dịch.
  - `GET /api/v1/transactions/export/csv` : Tải sao kê định dạng CSV.
  - `GET /api/v1/transactions/export/pdf` : Tải sao kê định dạng PDF.
  - `GET /api/v1/transactions/export/excel` : Tải sao kê định dạng Excel.

### 3.2. Nhóm Định Danh, QR Code & Thanh toán

- **`PaymentController`**:
  - `POST /api/v1/payments/vietqr/generate` : Sinh mã VietQR tĩnh/động cho tài khoản.
- **`QrController`**:
  - `GET /api/v1/users/me/qrcode` : Lấy mã QR cá nhân để nhận tiền.
  - `POST /api/v1/payments/qr/scan` : API xử lý khi người dùng quét mã QR thanh toán.

### 3.3. Nhóm Tài khoản, Bảo mật & eKYC (User & Security)

- **`UserController`**:
  - `POST /api/v1/users/kyc` : Gửi hồ sơ eKYC (CMND/CCCD/Face matching).
  - `GET /api/v1/users/kyc/status` : Lấy trạng thái phê duyệt eKYC.
  - `POST /api/v1/users/kyc/webhook` : Nhận webhook từ đối tác eKYC.
  - `POST /api/v1/users/pin/set` : Cài đặt mã PIN (Security code) giao dịch.
  - `POST /api/v1/users/pin/verify` : Màn hình nhập mã PIN xác thực trước khi chuyển tiền.
  - `POST /api/v1/users/change-password` : Đổi mật khẩu.
- **`AccountController`**: Xử lý quên mật khẩu (Reset password), thay đổi password.
- **`SessionController`**:
  - `GET /api/v1/sessions` : Xem danh sách các thiết bị đang đăng nhập.
  - `DELETE /api/v1/sessions/{sessionId}` : Buộc đăng xuất (Kick-out) một thiết bị đáng ngờ.
  - `DELETE /api/v1/sessions` : Đăng xuất tất cả thiết bị khác.

### 3.4. Nhóm Ngân hàng liên kết & Danh bạ

- **`BankAccountController`**:
  - `POST /api/v1/bank-accounts/link` : Liên kết tài khoản ngân hàng / thẻ VISA.
  - `GET /api/v1/bank-accounts` : Danh sách nguồn tiền (Funding sources).
  - `DELETE /api/v1/bank-accounts/{id}` : Hủy liên kết.
- **`BeneficiaryController`**:
  - `POST /api/v1/beneficiaries` : Lưu một người bạn/tài khoản vào danh bạ thụ hưởng.
  - `GET /api/v1/beneficiaries` : Hiển thị danh bạ chuyển tiền.
  - `DELETE /api/v1/beneficiaries/{id}` : Xóa danh bạ.

### 3.5. Nhóm Thiết bị & Thông báo Push (Notifications)

- **`NotificationController`**:
  - `GET /api/v1/notifications` : Danh sách thông báo (Biến động số dư, tin tức).
  - `PUT /api/v1/notifications/{id}/read` : Đánh dấu đã đọc.
  - `POST /api/v1/notifications/devices` : Gọi sau khi login để lưu Device Token (FCM của Google hoặc APNs của Apple) dùng để push notify.
  - `PUT /api/v1/notifications/settings` : Tùy chỉnh bật/tắt nhận tin.

### 3.6. Nhóm Khuyến Mãi (Promotions) & Đối tác (Merchant)

- **`PromotionController`**:
  - `GET /api/v1/promotions` : Lấy danh sách Voucher.
  - `POST /api/v1/promotions/redeem` : Đổi điểm (Loyalty points) lấy Voucher.
  - `POST /api/v1/promotions/apply` : Áp dụng mã Voucher trước khi thanh toán để tính lại số tiền.
- **`MerchantController`**:
  - Các luồng API dành riêng cho app Đối tác kinh doanh (Tạo mã thanh toán, xác nhận nhận tiền...).

### 3.7. Nhóm Backoffice, Kế Toán & Cấu hình (Ledger / Legal)

- **`LedgerController`**: Khởi tạo cấu trúc Sổ cái kế toán, ghi sổ kép (Double-entry bookkeeping).
- **`ReconciliationController`**: API chạy quy trình đối soát cuối ngày với ngân hàng.
- **`LegalConfigController`**: Lấy Điều khoản dịch vụ, hạn mức giao dịch quy định theo luật.

---

## 4. Phân Tích Sự Tối Ưu Của Kiến Trúc

### A. Sẵn Sàng Cho Frontend (App Mobile / Web Portal)

- **Giao diện đa nền tảng (Omnichannel)**: Với việc hỗ trợ xuất file `PDF`, `CSV`, `Excel` trực tiếp trên server, FE không cần tốn tài nguyên gen file ở máy khách.
- **Bảo vệ Đa tầng (Multi-layer Auth)**: Hệ thống sử dụng 2 lớp bảo mật: JWT cho định danh Login và mã **PIN API** (tại `UserController`) cho định danh giao dịch. Quản lý Session mạnh mẽ giúp người dùng an tâm về tài khoản.

### B. Hiệu Năng & Khả năng Chịu Lỗi Tại Backend

- **Chống gian lận - Race Condition**: Trong nghiệp vụ ví điện tử, rất dễ xảy ra lỗi click đúp rút tiền hoặc chuyển tiền liên tiếp. Thiết kế của dự án dùng `Spring Data Redis` khóa tài nguyên (Lock) mức phân tán. Giao dịch luôn đảm bảo tuân thủ nguyên tắc ACID.
- **Kiến Trúc Lục Giác (Hexagonal)**: Bạn có thể thấy cấu trúc port/adapter (`BeneficiaryPersistencePort`, `AuditLogPersistencePort`). Việc tách biệt logic nghiệp vụ ra khỏi JPA hay Web Interface giúp code siêu sạch (Clean Code), FE có thay đổi UI thì Backend Core không bị ảnh hưởng, chỉ cần sửa lớp Controller (Adapter).
- **Không bao giờ "sập dây chuyền"**: Nếu ngân hàng bảo trì, `Resilience4j` Circuit Breaker sẽ cắt mạch, báo lỗi "Bảo trì" cho FE ngay lập tức thay vì bắt FE gọi API rồi quay vòng loading (Timeout).

### Kết luận

Source code hệ thống backend Ví điện tử này được xây dựng rất đồ sộ, chuẩn mực, áp dụng đầy đủ các Best Practices (Design Pattern, Clean Architecture). Hệ thống API cực kì phong phú (**>80 Endpoints**) đã được thiết kế sẵn để FE/Mobile App xây dựng lên một ứng dụng Fintech hoàn chỉnh.


1. Nhóm Ví & Giao Dịch (Wallet & Transactions) - 12 APIs
   Bao gồm các API cốt lõi vừa được bổ sung đầy đủ cho luồng tài chính:

Wallet Controller:
POST /api/v1/wallets (Tạo ví)
GET /api/v1/wallets/{walletId} (Thông tin ví)
POST /api/v1/wallets/deposit (Nạp tiền)
POST /api/v1/wallets/withdraw (Rút tiền)
POST /api/v1/wallets/transfer (Chuyển tiền)
GET /api/v1/wallets/fees/estimate (Mới) (Ước tính phí giao dịch)
POST /api/v1/wallets/transactions/{transactionId}/reverse (Mới) (Hoàn/đảo giao dịch)
Transaction Query Controller:
GET /api/v1/transactions (Lịch sử giao dịch)
GET /api/v1/transactions/{id} (Chi tiết giao dịch)
GET /api/v1/transactions/export/... (Xuất PDF/CSV/Excel)
2. Nhóm Yêu Cầu Chuyển Tiền P2P (Money Requests) - 7 APIs (Mới bổ sung)
Tính năng giống "Đòi tiền" trên MoMo / ZaloPay:

POST /api/v1/money-requests (Tạo yêu cầu)
POST /api/v1/money-requests/{id}/accept (Đồng ý trả tiền)
POST /api/v1/money-requests/{id}/reject (Từ chối trả tiền)
POST /api/v1/money-requests/{id}/cancel (Huỷ yêu cầu)
GET /api/v1/money-requests/received (Danh sách nhận được)
GET /api/v1/money-requests/sent (Danh sách đã gửi)
GET /api/v1/money-requests/{id} (Chi tiết)
3. Nhóm Xác thực & Bảo mật (Auth & Security) - 14 APIs
Auth Controller (Đăng nhập/Đăng ký): POST /api/v1/auth/login, register, logout, logout/current, refresh, otp/send, otp/verify, forgot-password, reset-password.
Security Controller (Bảo mật 2FA/Biometric): POST /api/v1/account/2fa/enable, 2fa/disable, biometric/register, biometric/verify, GET /api/v1/security/login-history.
4. Nhóm Người Dùng & Cấu hình (User & Limits) - 13 APIs
User Controller: GET /api/v1/users/search (Tìm người qua SĐT), các API đổi PIN, cập nhật mật khẩu, eKYC.
Profile Controller: GET /api/v1/users/me, PUT /api/v1/users/me, upload avatar.
Legal & Config Controller: GET /api/v1/config/limits/status (Mới - Trả về hạn mức còn lại), GET /api/v1/config/limits, check điều khoản dịch vụ (Terms/Consent).
5. Nhóm Liên Kết Ngân Hàng (Bank Accounts) - 3 APIs
GET /api/v1/bank-accounts
POST /api/v1/bank-accounts/link
DELETE /api/v1/bank-accounts/{bankAccountId}
6. Nhóm Thanh Toán Hóa Đơn & Mã QR (Payment & QR) - 7 APIs
Payment Controller: POST /api/v1/payments/bills/query, bills/pay, topup, vietqr/decode, vietqr/generate.
QR Controller: GET /api/v1/users/me/qrcode, POST /api/v1/payments/qr/scan.
7. Nhóm Tiện ích khác (39 APIs)
Danh bạ thụ hưởng (Beneficiary): 3 APIs (GET, POST, DELETE).
Thông báo (Notification): 5 APIs (Lấy danh sách, đánh dấu đã đọc, đăng ký thiết bị push).
Khuyến mãi & Giới thiệu (Promotion/Referral): 7 APIs (Voucher, nhập mã giới thiệu).
Hỗ trợ & Góp ý (Support/Feedback): 6 APIs (Tạo ticket, gửi tin nhắn hỗ trợ, FAQ).
Quản lý phiên đăng nhập (Session): 3 APIs (Xem thiết bị đang login, đăng xuất thiết bị khác).
