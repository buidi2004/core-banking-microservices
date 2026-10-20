# BÁO CÁO KỸ THUẬT VÀ ĐẶC TẢ TÍCH HỢP CHO FRONTEND (FE INTEGRATION REPORT)
**Dự án:** Sen Hồng E-Wallet (Fintech App)  
**Ngày lập:** 05/09/2026  
**Người lập:** Backend Engineering Team  
**Đối tượng nhận:** Frontend Team (Flutter / Mobile Devs)

---

## MỤC LỤC
1. [Giải đáp & Xác nhận 9 điểm trọng yếu với Backend](#1-giải-đáp--xác-nhận-9-điểm-trọng-yếu-với-backend)
2. [Chi tiết đặc tả tích hợp từng phân hệ (Mục 2 -> 10)](#2-chi-tiết-đặc-tả-tích-hợp-từng-phân-hệ-mục-2---10)
   - [Mục 2. Auth + Token Refresh](#mục-2-auth--token-refresh)
   - [Mục 3. Home API](#mục-3-home-api)
   - [Mục 4. Transfer (Chuyển tiền)](#mục-4-transfer-chuyển-tiền)
   - [Mục 5. Deposit & Withdraw (Nạp / Rút tiền)](#mục-5-deposit--withdraw-nạp--rút-tiền)
   - [Mục 6. Bills / Utilities & QR Code](#mục-6-bills--utilities--qr-code)
   - [Mục 7. History & Receipt (Lịch sử & Sao kê/Biên lai)](#mục-7-history--receipt-lịch-sử--sao-kêbiên-lai)
   - [Mục 8. Profile, Cards & Settings](#mục-8-profile-cards--settings)
   - [Mục 9. WebSocket / FCM Push](#mục-9-websocket--fcm-push)
   - [Mục 10. Xử lý lỗi, Idempotency & UX](#mục-10-xử-lý-lỗi-idempotency--ux)
3. [Lộ trình triển khai & Tiêu chí nghiệm thu (Phase 1 + 2 Vertical Slice)](#3-lộ-trình-triển-khai--tiêu-chí-nghiệm-thu)

---

## 1. GIẢI ĐÁP & XÁC NHẬN 9 ĐIỂM TRỌNG YẾU VỚI BACKEND

### 1.1. Endpoint Refresh Token
- **Path:** `POST /api/v1/auth/refresh?refreshToken={token}`
- **Cách truyền:** `refreshToken` được truyền qua **Query Parameter** (hoặc `x-www-form-urlencoded`).
- **Header:** Không cần `Authorization` Bearer header (đây là public endpoint).
- **Cơ chế:** Silent refresh rotation – BE cấp mới đồng thời cả `accessToken` và `refreshToken`.
- **Response mẫu:**
  ```json
  {
    "success": true,
    "message": "Access token refreshed",
    "data": {
      "userId": "d7a456fe-1234-4b55-a678-9abcdef01234",
      "phoneNumber": null,
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi..."
    },
    "timestamp": "2026-09-05T04:30:00Z",
    "errorCode": null
  }
  ```
- **FE Handling:** Khi bất kỳ API nào trả về HTTP `401 Unauthorized`, `AuthInterceptor` giữ request lại (queue), gọi `POST /api/v1/auth/refresh`, lưu cặp token mới vào `FlutterSecureStorage`, sau đó retry lại request ban đầu. Nếu refresh thất bại -> Chuyển hướng người dùng về màn hình Login.

---

### 1.2. Cấu trúc lỗi chuẩn (Standard Error Structure)
Toàn bộ API (ngoại trừ các endpoint stream file nhị phân) đều trả về định dạng bọc thống nhất qua `ApiResponse<T>`:
```json
{
  "success": false,
  "message": "Thông điệp lỗi chi tiết hiển thị cho người dùng",
  "data": null,
  "timestamp": "2026-09-05T04:30:00Z",
  "errorCode": "INSUFFICIENT_BALANCE"
}
```

#### Bảng tra cứu `errorCode` và HTTP Status Code:
| HTTP Status | `errorCode` | Ý nghĩa nghiệp vụ | Hành động khuyến nghị cho FE |
|:---|:---|:---|:---|
| **401** | *None* | Access Token hết hạn hoặc không hợp lệ | Kích hoạt Silent Refresh Token |
| **401** | `INVALID_PIN` | Mã PIN hoặc OTP không chính xác | Hiển thị cảnh báo số lần nhập còn lại |
| **423** / **400** | `ACCOUNT_LOCKED` | Khóa tài khoản tạm thời (sai PIN/OTP quá 3 lần: khóa 15p; sai pass 5 lần) | Khóa giao diện, hiển thị đếm ngược 15 phút |
| **404** | `WALLET_NOT_FOUND` | Không tìm thấy ví tương ứng | Thông báo kiểm tra lại thông tin ví |
| **404** | `USER_NOT_FOUND` | Người nhận không tồn tại | Báo đỏ trường số điện thoại người nhận |
| **400** | `INSUFFICIENT_BALANCE`| Số dư khả dụng không đủ cho giao dịch | Báo lỗi kèm gợi ý nạp thêm tiền |
| **400** | `LIMIT_EXCEEDED` | Vượt hạn mức giao dịch (ngày hoặc tháng) | Yêu cầu nâng cấp eKYC hoặc chờ ngày hôm sau |
| **400** | `VALIDATION_FAILED`| Lỗi validation (thiếu field, regex fail) | Hiển thị inline error từng input field |
| **400** | `BAD_REQUEST` | Tham số gửi lên không đúng định dạng | Hiển thị toast cảnh báo |
| **403** | `KYC_REQUIRED` | Giao dịch yêu cầu tài khoản phải định danh eKYC | Điều hướng người dùng sang flow eKYC |
| **409** | `CONCURRENT_CONFLICT` | Xung đột phiên bản (Optimistic lock conflict) | Tự động retry tối đa 3 lần (exponential backoff) |
| **429** | `SYSTEM_BUSY` | Distributed lock đang bận xử lý giao dịch song song | Đợi 1-2s và tự động retry |
| **500** | `INTERNAL_SERVER_ERROR`| Lỗi nội bộ server không lường trước | Báo lỗi hệ thống chung, không văng app |

---

### 1.3. `walletId` lấy từ đâu sau login?
Backend cung cấp **2 phương án** để FE lấy `walletId` ngay sau khi đăng nhập:

- **Phương án 1 (Khuyến nghị chuẩn RESTful - BE vừa kích hoạt):**
  - **Endpoint:** `GET /api/v1/wallets/me`
  - **Header:** `Authorization: Bearer {accessToken}`
  - **Response:**
    ```json
    {
      "success": true,
      "message": "Wallet retrieved successfully",
      "data": {
        "id": "e81d43f0-0b32-4d2a-89a3-5c8e31289190",
        "ownerId": "d7a456fe-1234-4b55-a678-9abcdef01234",
        "balance": 5000000.00,
        "currency": "VND",
        "createdAt": "2026-09-01T10:00:00Z",
        "updatedAt": "2026-09-05T04:00:00Z"
      }
    }
    ```
  - FE lấy `data.id` làm `walletId` và lưu vào Session State / Secure Storage.

- **Phương án 2 (Dự phòng theo số điện thoại):**
  - **Endpoint:** `GET /api/v1/wallets/recipient-info?phoneNumber={currentUserPhone}`
  - **Response:**
    ```json
    {
      "success": true,
      "message": "Recipient information retrieved successfully",
      "data": {
        "walletId": "e81d43f0-0b32-4d2a-89a3-5c8e31289190",
        "phoneNumber": "0987654321",
        "maskedName": "NGUYEN V** AN",
        "fullName": "NGUYEN VAN AN"
      }
    }
    ```

---

### 1.4. Quy tắc PIN/OTP và Mã Lỗi Giao Dịch
- **Quy tắc sinh & Quản lý OTP:**
  - OTP gồm **6 chữ số ngẫu nhiên**, được BE tự sinh và lưu vào Redis với key `otp:trans:{transactionId}`.
  - **TTL OTP:** Đúng **5 phút**. Quá 5 phút OTP tự hủy.
  - **Single-use:** OTP bị xóa ngay sau lần xác thực thành công đầu tiên.
  - **Môi trường Dev:** OTP in ra console log server của backend để test.
- **Quy tắc PIN (Transaction PIN):**
  - PIN gồm **6 chữ số** định dạng `^\d{6}$`.
  - Thiết lập qua `POST /api/v1/users/pin/set`.
  - Được hash bằng BCrypt trước khi lưu vào DB.
  - Dùng cho: Rút tiền (yêu cầu `pinToken` sinh từ `POST /api/v1/users/pin/verify`) hoặc Chuyển tiền (truyền trực tiếp qua param `?pin=123456`).
- **Quy tắc khóa tài khoản (Lockout):**
  - Tối đa **3 lần** nhập sai liên tiếp (cộng dồn cả PIN và OTP).
  - Lần thứ 3 sai -> Khóa tài khoản trong **15 phút** (`locked_user:{userId}`).
  - Trong thời gian khóa, mọi request confirm trả về lỗi `INVALID_PIN` với message: *"Account is temporarily locked due to too many failed attempts. Try again later."*.
  - Nhập đúng -> Bộ đếm lỗi tự động reset về 0.

---

### 1.5. Response chính xác của `POST /api/v1/wallets/transfer/init`
- **Request Body:**
  ```json
  {
    "requestId": "550e8400-e29b-41d4-a716-446655440000",
    "sourceWalletId": "e81d43f0-0b32-4d2a-89a3-5c8e31289190",
    "targetWalletId": "c92e54a1-1c43-5e3b-90b4-6d9f42390201",
    "amount": 100000.00,
    "currency": "VND",
    "bankCode": "SENHONG",
    "note": "Tien an trua"
  }
  ```
- **Response chính xác (HTTP 200 OK):**
  ```json
  {
    "success": true,
    "message": "Transfer initiated. Please confirm with OTP/PIN.",
    "data": {
      "transactionId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "requestId": "550e8400-e29b-41d4-a716-446655440000",
      "sourceWalletId": "e81d43f0-0b32-4d2a-89a3-5c8e31289190",
      "targetWalletId": "c92e54a1-1c43-5e3b-90b4-6d9f42390201",
      "amount": 100000.00,
      "currency": "VND",
      "type": "TRANSFER",
      "status": "PENDING_CONFIRMATION",
      "timestamp": "2026-09-05T04:35:00Z",
      "note": "Tien an trua",
      "bankCode": "SENHONG",
      "feeAmount": 0.00
    },
    "timestamp": "2026-09-05T04:35:00Z",
    "errorCode": null
  }
  ```
  > **Lưu ý đặc biệt cho FE:**
  > - Trường `balance` ở bước này là `null` (backend áp dụng `@JsonInclude(NON_NULL)` nên trường này sẽ không xuất hiện trong JSON). Tiền **chưa bị trừ** khỏi tài khoản người gửi.
  > - FE lấy `data.transactionId` để truyền vào URL màn hình xác thực: `POST /api/v1/wallets/transfer/{transactionId}/confirm?otp=...` hoặc `?pin=...`.

---

### 1.6. Cách truyền tải và xử lý Binary PDF / Export
- **Danh sách endpoint:**
  - `GET /api/v1/transactions/{id}/receipt.pdf` (Biên lai giao dịch)
  - `GET /api/v1/transactions/export/pdf?walletId={id}&fromDate={iso}&toDate={iso}` (Sao kê PDF)
  - `GET /api/v1/transactions/export/csv?walletId={id}` (Sao kê CSV)
  - `GET /api/v1/transactions/export/excel?walletId={id}` (Sao kê Excel)
- **Header gửi lên:** Bắt buộc có `Authorization: Bearer {accessToken}`.
- **Định dạng trả về:** **Raw Binary Data Stream** (`byte[]`), **KHÔNG BỌC** trong JSON `ApiResponse`.
- **Response Headers:**
  - PDF: `Content-Type: application/pdf`, `Content-Disposition: inline; filename="receipt_{id}.pdf"`
  - CSV: `Content-Type: text/csv`, `Content-Disposition: attachment; filename="statement_{walletId}.csv"`
  - Excel: `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **Cách cấu hình Dio phía Flutter:**
  ```dart
  final response = await dio.get(
    ApiConstants.receiptPdf(transactionId),
    options: Options(
      responseType: ResponseType.bytes, // Bắt buộc
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  Uint8List pdfBytes = Uint8List.fromList(response.data);
  // Lưu file qua path_provider hoặc mở trực tiếp bằng printing / open_filex
  ```

---

### 1.7. WebSocket: STOMP hay Native WebSocket?
- **Giao thức chuẩn:** **BẮT BUỘC DÙNG GIAO THỨC STOMP** (Spring WebSocket Message Broker).
- **Endpoint cho Mobile (Flutter / React Native):**
  - **URL:** `ws://{host}:{port}/ws-native`
  - *(Lưu ý: Endpoint `/ws` dành cho Web với SockJS fallback; Mobile dùng `/ws-native` là WebSocket thuần, nhưng payload bên trong phải tuân thủ khung STOMP).*
- **Thư viện Flutter khuyến nghị:** `stomp_dart_client`.
- **Quy trình kết nối:**
  1. Kết nối đến `ws://{host}:{port}/ws-native`.
  2. Gửi STOMP `CONNECT` frame kèm Header:
     `stompConnectHeaders: {'Authorization': 'Bearer $accessToken'}`
  3. Khi nhận STOMP `CONNECTED` frame, tiến hành Subscribe Topic:
     `stompClient.subscribe(destination: '/topic/users/$userId/notifications', callback: ...)`
- **Payload nhận được:** Chuỗi JSON chứa `NotificationPayload` (khớp 100% với data field của FCM push).

---

### 1.8. VPS Server & Android / iOS Dev Base URL

#### Địa chỉ chính xác của Server VPS:
* **Host IP VPS:** `180.93.120.246`
* **Port Backend:** `8080`
* **Base REST API URL (VPS):** `http://180.93.120.246:8080/api/v1`
* **WebSocket STOMP URL (VPS):** `ws://180.93.120.246:8080/ws-native`
* **Swagger API Docs (VPS):** `http://180.93.120.246:8080/swagger-ui/index.html`

*(Đã kiểm tra kết nối trực tiếp đến VPS `180.93.120.246`: Auth Login, Query Wallets, Set PIN, Chuyển tiền Realtime phản hồi HTTP 200 OK ngay lập tức).*

#### Các cấu hình Base URL dự phòng khi chạy Localhost:
* **Android Emulator:** `http://10.0.2.2:8080/api/v1` (WS: `ws://10.0.2.2:8080/ws-native`)
* **iOS Simulator:** `http://localhost:8080/api/v1` (WS: `ws://localhost:8080/ws-native`)

---

### 1.9. Quyền và Flow Upload Ảnh eKYC
- **Hiện trạng Backend:** Backend tập trung vào core ledger/fintech nên **không tiếp nhận multipart binary upload trực tiếp** (tránh nghẽn I/O server và tốn băng thông ứng dụng).
- **Endpoint KYC:** `POST /api/v1/users/kyc`
  - Nhận body JSON chứa các đường dẫn ảnh đã upload thành công:
    ```json
    {
      "idCardNumber": "079090001234",
      "fullName": "NGUYEN VAN AN",
      "dob": "1995-08-15",
      "frontCardUrl": "https://cdn.senhong.vn/kyc/front_uuid.jpg",
      "backCardUrl": "https://cdn.senhong.vn/kyc/back_uuid.jpg",
      "selfieUrl": "https://cdn.senhong.vn/kyc/selfie_uuid.jpg"
    }
    ```
- **Flow thực thi cho FE:**
  - **Giai đoạn phát triển (Dev/Test):** FE có thể sử dụng ảnh mock URL từ CDN công khai hoặc storage demo.
  - **Giai đoạn Staging/Production:** FE upload trực tiếp từ điện thoại lên Cloud Storage (Firebase Storage, AWS S3 Pre-signed URL hoặc Cloudinary) -> Lấy URL công khai/bảo mật -> Gọi `POST /api/v1/users/kyc`.

---

## 2. CHI TIẾT ĐẶC TẢ TÍCH HỢP TỪNG PHÂN HỆ (MỤC 2 -> 10)

### Mục 2. Auth + Token Refresh
| Method | Endpoint | Tham số / Body | Response Data | Ghi chú nghiệp vụ |
|:---|:---|:---|:---|:---|
| POST | `/auth/register` | `{phoneNumber*, fullName*, password*, deviceId}` | `AuthResponse` | Đăng ký tài khoản và tự động tạo ví mặc định VND |
| POST | `/auth/login` | `{phoneNumber*, password*, deviceId}` | `AuthResponse` | Đăng nhập hệ thống (Rate limit: 10 lần/phút) |
| POST | `/auth/refresh` | `?refreshToken={token}` | `AuthResponse` | Cấp mới accessToken & refreshToken ngầm |
| POST | `/auth/otp/send` | `?phoneNumber={phone}` | `null` | Gửi mã OTP đăng ký / quên mật khẩu |
| POST | `/auth/otp/verify` | `?phoneNumber=&otp=` | `Boolean` | Xác thực OTP 6 số |
| POST | `/auth/forgot-password` | `?phoneNumber=` | `null` | Gửi OTP khôi phục mật khẩu |
| POST | `/auth/reset-password` | `?phoneNumber=&otp=&newPassword=` | `null` | Đặt lại mật khẩu mới |
| POST | `/auth/logout` | Header: `Authorization: Bearer {token}` | `null` | Đưa token hiện tại vào blacklist (Redis) |

---

### Mục 3. Home API
Để xây dựng trọn vẹn màn hình Home Dashboard mà không cần hardcode:
1. **Lấy số dư và thông tin ví:** `GET /api/v1/wallets/me` -> Lấy `id` (walletId), `balance`, `currency`.
2. **Lấy thông tin User Profile:** `GET /api/v1/users/me` -> Lấy `fullName`, `avatarUrl`, `email`.
3. **Lấy trạng thái hạn mức:** `GET /api/v1/config/limits/status` -> Lấy `dailyLimit`, `dailySpent`, `dailyRemaining`, `kycLevel`.
4. **Lấy 5 giao dịch gần nhất:** `GET /api/v1/transactions?walletId={walletId}&page=0&size=5`.

---

### Mục 4. Transfer (Chuyển tiền)
**Step-by-step luồng chuyển tiền:**
1. **Tra cứu người nhận:** `GET /api/v1/wallets/recipient-info?phoneNumber={phone}`
   - Trả về `walletId` người nhận và `maskedName` ("NGUYEN V** AN") để hiển thị trên UI.
2. **Tính toán phí giao dịch:** `GET /api/v1/wallets/fees/estimate?type=TRANSFER&amount={amount}&currency=VND`
   - Chuyển nội bộ `SENHONG` phí là `0 VND`.
3. **Khởi tạo giao dịch:** `POST /api/v1/wallets/transfer/init`
   - Body: `{requestId, sourceWalletId, targetWalletId, amount, currency, bankCode, note}`
   - Header: `Idempotency-Key: {requestId}`
   - Nhận về `transactionId`, trạng thái `PENDING_CONFIRMATION`. OTP 6 số được sinh ngầm.
4. **Xác nhận giao dịch:** `POST /api/v1/wallets/transfer/{transactionId}/confirm?otp={otp}` (hoặc `?pin={pin}`)
   - Trả về `TransferResponse` với `status = "SUCCESS"` và `balance` (số dư mới của người gửi).

---

### Mục 5. Deposit & Withdraw (Nạp / Rút tiền)
- **Nạp tiền (Deposit):**
  - `POST /api/v1/wallets/deposit`
  - Body: `{requestId*, walletId*, amount*, currency*}`
  - Header: `Idempotency-Key: {requestId}`
  - Trả về `TransferResponse` thành công, số dư tài khoản tăng ngay lập tức.
- **Rút tiền (Withdraw):**
  - **Bước 1:** Xác thực PIN để lấy vé ủy quyền: `POST /api/v1/users/pin/verify` kèm `{pin: "123456"}` -> Nhận `pinToken` (JWT ngắn hạn).
  - **Bước 2:** Gọi rút tiền: `POST /api/v1/wallets/withdraw`
    - Body: `{requestId*, walletId*, bankAccountId*, amount*, currency*, pinToken*}`
    - Header: `Idempotency-Key: {requestId}`

---

### Mục 6. Bills / Utilities & QR Code
- **Tra cứu hóa đơn:** `GET /api/v1/bills/lookup?type={ELECTRICITY|WATER|INTERNET|TUITION}&customerCode={code}`
- **Thanh toán hóa đơn:** `POST /api/v1/bills/pay`
  - Body: `{requestId, walletId, billId, amount, currency}`
- **Nạp tiền điện thoại (Top-up):** `POST /api/v1/bills/topup`
  - Body: `{requestId, walletId, phoneNumber, amount, currency}`
- **VietQR Decode:** `POST /api/v1/payments/vietqr/decode?qrString={rawQrString}`
  - Trả về thông tin: ngân hàng, số tài khoản/số điện thoại người nhận, số tiền, nội dung.
- **Khởi tạo chuyển tiền qua QR:** `POST /api/v1/wallets/transfer/qr/init`
  - Body: `{requestId, sourceWalletId, qrCode, amount, currency}`

---

### Mục 7. History & Receipt (Lịch sử & Sao kê/Biên lai)
- **Danh sách giao dịch:** `GET /api/v1/transactions?walletId={walletId}&type={TRANSFER|DEPOSIT|WITHDRAWAL}&page=0&size=20`
  - Phân loại trực quan: `type` đã được backend tự động phân định thành `TRANSFER_OUT` (tiền đi) hoặc `TRANSFER_IN` (tiền về) theo ví đang xem.
  - Trường `runningBalance` là số dư sau giao dịch tương ứng.
- **Chi tiết giao dịch:** `GET /api/v1/transactions/{id}`
- **Tải biên lai PDF:** `GET /api/v1/transactions/{id}/receipt.pdf` (Raw `byte[]`).
- **Xuất sao kê:** `GET /api/v1/transactions/export/{csv|pdf|excel}?walletId={walletId}&fromDate=&toDate=` (Raw `byte[]`).

---

### Mục 8. Profile, Cards & Settings
- **Thông tin cá nhân:** `GET /api/v1/users/me` & cập nhật qua `PUT /api/v1/users/me?fullName=&email=&dob=`.
- **Tài khoản ngân hàng liên kết:**
  - `GET /api/v1/bank-accounts` (Danh sách tài khoản).
  - `POST /api/v1/bank-accounts/link` (`{bankCode, accountNumber, accountHolderName}`).
  - `DELETE /api/v1/bank-accounts/{bankAccountId}` (Hủy liên kết).
- **Thẻ ngân hàng (Funding Sources):**
  - `GET /api/v1/funding-sources` | `POST /api/v1/funding-sources/link` | `DELETE /api/v1/funding-sources/{id}`.
- **Quản lý phiên đăng nhập & thiết bị:**
  - `GET /api/v1/sessions` (Xem danh sách thiết bị đang đăng nhập).
  - `DELETE /api/v1/sessions/{deviceId}` (Đăng xuất từ xa thiết bị đó).
  - `DELETE /api/v1/sessions` (Đăng xuất khỏi tất cả các thiết bị khác).

---

### Mục 9. WebSocket / FCM Push
- **Đăng ký Token FCM cho Push Notification (Background/Killed state):**
  - `POST /api/v1/devices/register`
  - Body: `{ "fcmToken": "c-N6Vq7...", "deviceType": "ANDROID" }` (hoặc `"IOS"`).
- **Hủy FCM Token khi Logout:**
  - `DELETE /api/v1/devices/unregister?fcmToken={token}`.
- **Schema dữ liệu biến động số dư (Dùng chung cho cả STOMP và FCM `data`):**
  ```json
  {
    "transactionId": "uuid",
    "requestId": "client-uuid",
    "type": "TRANSFER_IN",
    "status": "SUCCESS",
    "walletId": "uuid",
    "amount": "50000.00",
    "currency": "VND",
    "newBalance": "1550000.00",
    "timestamp": "2026-09-05T04:40:00Z",
    "note": "Chuyen tien ca phe",
    "title": "Biến động số dư: +50,000 VND",
    "body": "TK nhận thành công 50,000 VND từ TRAN THI BINH"
  }
  ```

---

### Mục 10. Xử lý lỗi, Idempotency & UX
1. **Header Idempotency-Key:**
   - Mọi request tạo thay đổi số dư (`/deposit`, `/transfer/init`, `/withdraw`, `/bills/pay`) phải đính kèm Header:
     `Idempotency-Key: {uuid-v4}`
   - Giúp bảo đảm nếu người dùng bấm đúp hoặc rớt mạng kết nối chập chờn, giao dịch không bao giờ bị trừ tiền 2 lần.
2. **Xử lý xung đột lạc quan (HTTP 409 `CONCURRENT_CONFLICT`):**
   - Khi có 2 giao dịch đồng thời trên 1 ví, DB chặn dirty write và trả về HTTP 409.
   - FE áp dụng Exponential Backoff Retry (thử lại sau 200ms, 500ms, 1000ms).
3. **Xử lý phân tán (HTTP 429 `SYSTEM_BUSY`):**
   - Redis Lock đang được giữ bởi luồng khác, FE tự động retry sau 1 giây.
4. **UX Trạng thái:**
   - Mọi màn hình phải có đủ 4 trạng thái: `Loading (Shimmer Skeleton)`, `Error (với nút Retry)`, `Empty (Trống)`, và `Data Content`.

---

## 3. LỘ TRÌNH TRIỂN KHAI & TIÊU CHÍ NGHIỆM THU

### 3.1. Kế hoạch Phase 1 + Phase 2 (Vertical Slice)
**Mục tiêu chính:** Hoàn thiện luồng kiểm thử từ đầu đến cuối:
$$\text{Login} \longrightarrow \text{Lưu Token} \longrightarrow \text{Gọi } \texttt{GET /wallets/me} \longrightarrow \text{Hiển thị Số dư & User Profile thật trên Home}$$

1. **Bước 1 (Core Network):**
   - Cập nhật `ApiConstants.baseUrl` chuẩn cho Emulator (`http://10.0.2.2:8080/api/v1`) hoặc iOS Simulator (`http://localhost:8080/api/v1`).
   - Cấu hình `AuthInterceptor` gắn Bearer token và bắt mã 401 gọi Silent Refresh.
2. **Bước 2 (Auth Flow):**
   - Màn hình `LoginScreen`: Gửi `POST /auth/login`. Nhận `accessToken`, `refreshToken`, `userId`, `phoneNumber`.
   - Lưu vào `FlutterSecureStorage`.
3. **Bước 3 (Home Flow - Vertical Slice):**
   - Màn hình `HomeScreen`: Gọi song song `GET /wallets/me` và `GET /users/me`.
   - Bỏ toàn bộ mock data tĩnh, hiển thị đúng số dư VND thật từ database backend.
   - Hiển thị Shimmer Skeleton khi đang tải, hiển thị nút Retry khi gặp lỗi mạng.

### 3.2. Tiêu chí nghiệm thu (Acceptance Criteria)
Mỗi flow được xác nhận hoàn tất khi đạt đủ các tiêu chuẩn sau:
- [x] **API Thật 100%:** Toàn bộ dữ liệu hiển thị lấy từ backend Spring Boot qua HTTP Client, không còn dữ liệu fake/mock trong state.
- [x] **Quản lý Token tự động:** Access token hết hạn tự động refresh ngầm; nếu refresh token hết hạn thì đẩy về Login một cách mượt mà.
- [x] **Trạng thái UX toàn diện:** Đầy đủ `Loading Skeleton`, `Error view có nút Thử lại`, `Empty state view`.
- [x] **An toàn giao dịch:** Có header `Idempotency-Key` với UUID v4 ngẫu nhiên cho mỗi lần gửi giao dịch tiền.
- [x] **Độ bao phủ trạng thái:** Màn hình giao dịch kiểm thử và hiển thị đúng cả 3 trạng thái: `SUCCESS`, `PENDING_CONFIRMATION`, và `FAILED`.
