# HƯỚNG DẪN PHÁT TRIỂN FRONTEND TỪ BACKEND API

Tài liệu này ánh xạ các chức năng của Backend (các API endpoints) sang các màn hình Frontend tương ứng, đồng thời đề xuất **thứ tự ưu tiên phát triển** để đội ngũ Frontend (React Native / Web) có thể xây dựng ứng dụng một cách logic, không bị tắc nghẽn luồng dữ liệu (Blocking).

---

## 🚀 GIAI ĐOẠN 1: XÁC THỰC & ĐỊNH DANH (AUTH)
*Giai đoạn này cung cấp các luồng đăng nhập, đăng ký và quản lý phiên. Phải làm đầu tiên để có JWT Token giao tiếp với các API khác.*

### 1. Màn hình Khởi động (Splash / Onboarding)
- Kiểm tra trạng thái đăng nhập, gọi API Refresh Token nếu JWT hết hạn (Silent Refresh).
- **API:** `POST /api/v1/auth/refresh`

### 2. Màn hình Đăng Ký (Register) & Xác Thực OTP
- Người dùng nhập Số điện thoại, Mật khẩu -> Đăng ký.
- **API:** `POST /api/v1/auth/register` (Tạo user, trả về yêu cầu OTP).
- **API:** `POST /api/v1/auth/otp/send` (Gửi lại OTP nếu cần).
- **API:** `POST /api/v1/auth/otp/verify` (Xác minh OTP để kích hoạt tài khoản).

### 3. Màn hình Đăng Nhập (Login)
- Người dùng nhập Số điện thoại và Mật khẩu. Trả về Access Token (TTL 5 phút) và Refresh Token.
- **API:** `POST /api/v1/auth/login`

### 4. Màn hình Quên Mật Khẩu (Forgot Password)
- Yêu cầu cấp lại mật khẩu thông qua Số điện thoại và OTP.
- **API:** `POST /api/v1/auth/forgot-password` (Yêu cầu cấp lại)
- **API:** `POST /api/v1/auth/reset-password` (Đặt lại mật khẩu)

---

## 🛡️ GIAI ĐOẠN 2: BẢO MẬT & THIẾT LẬP TÀI KHOẢN (SECURITY & PROFILE)
*Sau khi đăng nhập thành công, người dùng cần thiết lập các yếu tố bảo mật trước khi giao dịch.*

### 5. Màn hình Cài đặt Bảo mật (Security Settings)
- Kích hoạt sinh trắc học (Vân tay/FaceID), Bật/Tắt 2FA, Đổi mật khẩu.
- **API:** `POST /api/v1/security/biometric/register`
- **API:** `POST /api/v1/security/biometric/verify`
- **API:** `POST /api/v1/account/2fa/enable` / `disable`
- **API:** `POST /api/v1/account/password/change`

### 6. Màn hình Quản Lý Thiết Bị Đăng Nhập (Device Sessions)
- Quản lý các thiết bị đang đăng nhập, cho phép đăng xuất từ xa.
- **API:** `GET /api/v1/sessions` (Danh sách thiết bị)
- **API:** `DELETE /api/v1/sessions/{deviceId}` (Đăng xuất từ xa)
- **API:** `POST /api/v1/auth/logout/current` (Đăng xuất thiết bị hiện tại)

---

## 💳 GIAI ĐOẠN 3: LÕI VÍ ĐIỆN TỬ (WALLET CORE)
*Hiển thị màn hình chính (Home Dashboard) và kiểm tra số dư.*

### 7. Màn hình Trang Chủ (Home Dashboard)
- Hiển thị số dư hiện tại, thông tin Ví.
- Cần lấy `walletId` của người dùng đang đăng nhập thông qua Profile/Recipient.
- **API:** `GET /api/v1/wallets/recipient-info?phoneNumber={myPhone}` (Lấy UUID của ví)
- **API:** `GET /api/v1/wallets/{walletId}` (Lấy chi tiết số dư)
- **API:** `GET /api/v1/users/me/qrcode` (Lấy mã QR nhận tiền của bản thân)

---

## 💸 GIAI ĐOẠN 4: LUỒNG GIAO DỊCH TÀI CHÍNH (TRANSACTIONS)
*Giai đoạn phức tạp nhất: Nạp, Rút, và Chuyển tiền (yêu cầu mã PIN/OTP).*

### 8. Màn hình Chuyển Tiền & Chọn Người Nhận
- Nhập số điện thoại đối phương, tra cứu Tên người nhận (đã che mờ - Masking).
- **API:** `GET /api/v1/wallets/recipient-info?phoneNumber={targetPhone}`

### 9. Màn hình Nhập Số Tiền & Khởi Tạo Giao Dịch
- Kiểm tra phí giao dịch trước khi chuyển, sau đó tạo giao dịch PENDING.
- **API:** `GET /api/v1/wallets/fees/estimate` (Ước tính phí)
- **API:** `POST /api/v1/wallets/transfer/init` (Khởi tạo, trả về `transactionId`)

### 10. Màn hình Xác Thực Chuyển Tiền (Xác minh PIN/OTP)
- Xác nhận giao dịch đã khởi tạo bằng mã PIN hoặc OTP.
- **API:** `POST /api/v1/wallets/transfer/{transactionId}/confirm` (Hoàn tất giao dịch)

### 11. Màn hình Nạp / Rút Tiền (Deposit/Withdraw)
- Nạp tiền từ ngân hàng liên kết hoặc Rút tiền về ngân hàng.
- **API:** `POST /api/v1/wallets/deposit`
- **API:** `POST /api/v1/wallets/withdraw`

---

## 📱 GIAI ĐOẠN 5: THANH TOÁN QR & DỊCH VỤ (QR & BILL PAYMENT)
*Các tính năng thanh toán mở rộng.*

### 12. Màn hình Quét Mã QR (QR Scanner)
- Quét mã QR (EMVCo/VietQR), giải mã thông tin.
- **API:** `POST /api/v1/payments/vietqr/decode` (Giải mã)
- **API:** `POST /api/v1/wallets/transfer/qr/init` (Khởi tạo chuyển khoản qua QR)

### 13. Màn hình Thanh Toán Hóa Đơn & Nạp Tiền Điện Thoại
- Tra cứu nợ cước (Điện, nước) và Thanh toán (hoặc Topup điện thoại).
- **API:** `GET /api/v1/payments/bills/query` (Tra cứu cước)
- **API:** `POST /api/v1/payments/bills/pay` (Thanh toán hóa đơn)
- **API:** `POST /api/v1/payments/topup` (Nạp thẻ điện thoại)

---

## 📊 GIAI ĐOẠN 6: LỊCH SỬ GIAO DỊCH & SAO KÊ
*Phục vụ việc tra cứu và đối soát của khách hàng.*

### 14. Màn hình Lịch Sử Giao Dịch (Transaction History)
- Hiển thị danh sách giao dịch có phân trang (Pagination).
- **API:** `GET /api/v1/transactions` (Phân trang, bộ lọc)
- **API:** `GET /api/v1/transactions/{id}` (Chi tiết 1 giao dịch)

### 15. Màn hình Xuất Sao Kê / Biên Lai
- Tải file PDF biên lai điện tử hoặc file CSV/Excel thống kê.
- **API:** `GET /api/v1/transactions/export/pdf?transactionId={id}`
- **API:** `GET /api/v1/transactions/export/excel`
- **API:** `GET /api/v1/transactions/export/csv`

---

## 🔔 GIAI ĐOẠN 7: DANH BẠ & THÔNG BÁO (EXTRAS)

### 16. Màn hình Danh Bạ Thụ Hưởng (Beneficiaries)
- Lưu danh bạ để chuyển tiền nhanh.
- **API:** `GET /api/v1/beneficiaries`
- **API:** `POST /api/v1/beneficiaries`
- **API:** `DELETE /api/v1/beneficiaries/{id}`

### 17. Màn hình Thông Báo (Notifications)
- Hiển thị danh sách thông báo biến động số dư.
- Đăng ký FCM Token cho thiết bị để nhận Push.
- **API:** `POST /api/v1/sessions/{deviceId}/fcm` (Gửi token đẩy thông báo về BE)
- Cổng kết nối WebSockets: `ws://<domain>/ws` (Lắng nghe topic `/topic/wallets/{walletId}/notifications`)

---

## 📌 TÓM TẮT THỨ TỰ ƯU TIÊN SPRINT (DÀNH CHO PM/DEV LEAD)
- **Sprint 1:** Giai đoạn 1 + 3 (Auth & Wallet Core) -> Chạy được Dashboard, hiển thị số dư.
- **Sprint 2:** Giai đoạn 4 (Transactions) -> Luồng tiền cốt lõi (Nạp, Chuyển tiền, Xác thực PIN).
- **Sprint 3:** Giai đoạn 6 (History & Export) -> Xem lại lịch sử các luồng tiền đã chạy.
- **Sprint 4:** Giai đoạn 5 (QR & Bills) -> Tiện ích mở rộng.
- **Sprint 5:** Giai đoạn 2 & 7 (Security, Sessions, Notifications, Beneficiaries) -> Hoàn thiện trải nghiệm (Push notify, 2FA, Danh bạ).
