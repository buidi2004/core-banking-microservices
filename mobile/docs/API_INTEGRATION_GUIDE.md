# API Integration Guide — Sen Hồng E-Wallet Backend

> **VPS Base URL (Staging):** `http://180.93.120.246:8080`  
> **Local Base URL (Dev):** `http://localhost:8080`  
> **Auth:** `Authorization: Bearer {accessToken}` (JWT)  
> **Idempotency:** Header `Idempotency-Key: {uuid}` cho mọi POST thay đổi số dư  
> **WebSocket React Native / Flutter (VPS):** `ws://180.93.120.246:8080/ws-native`  
> **WebSocket Web/SockJS (VPS):** `ws://180.93.120.246:8080/ws`  
> **Subscribe Topic:** `/topic/users/{userId}/notifications`  
> **RabbitMQ Management (VPS):** `http://180.93.120.246:15672` (guest/guest)  

---

## 🌐 Hướng dẫn Kết nối Frontend với VPS Server

### 1. Thông số Kết nối Môi trường VPS
| Mục | Địa chỉ / Cổng | Ghi chú |
|---|---|---|
| **Host IP** | `180.93.120.246` | IP máy chủ VPS |
| **Backend API (REST)** | `http://180.93.120.246:8080` | Prefix API: `/api/v1/...` |
| **WebSocket (Native)** | `ws://180.93.120.246:8080/ws-native` | React Native / Flutter (Raw STOMP) |
| **WebSocket (Web)** | `ws://180.93.120.246:8080/ws` | Web browser / SockJS |
| **RabbitMQ Dashboard** | `http://180.93.120.246:15672` | Tra cứu queue/message lúc test |

---

### 2. Mẫu Cấu hình Biến Môi Trường (`.env`)

#### 📱 React Native (Expo)
Tạo hoặc cập nhật file `.env`:
```env
EXPO_PUBLIC_API_URL=http://180.93.120.246:8080
EXPO_PUBLIC_WS_URL=ws://180.93.120.246:8080/ws-native
```

#### 📱 React Native (CLI) / React Native Config
```env
API_BASE_URL=http://180.93.120.246:8080
WS_URL=ws://180.93.120.246:8080/ws-native
```

#### 💻 ReactJS (Vite)
```env
VITE_API_BASE_URL=http://180.93.120.246:8080
VITE_WS_URL=ws://180.93.120.246:8080/ws
```

#### 💻 Next.js
```env
NEXT_PUBLIC_API_URL=http://180.93.120.246:8080
NEXT_PUBLIC_WS_URL=ws://180.93.120.246:8080/ws
```

---

### 3. Lưu ý Bắt Buộc Khi Chạy Trên Thiết Bị Di Động (Mobile)

Do VPS hiện kết nối qua giao thức **HTTP (chưa gắn SSL domain HTTPS)**, hệ điều hành Android và iOS mặc định sẽ chặn kết nối không mã hóa (Cleartext Traffic). Cần mở quyền kết nối như sau:

#### Android: Cho phép HTTP Cleartext
Trong `android/app/src/main/AndroidManifest.xml`, thêm thuộc tính `android:usesCleartextTraffic="true"` vào thẻ `<application>`:
```xml
<application
    android:name=".MainApplication"
    android:label="@string/app_name"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true"
    ... >
```

#### iOS: Cấu hình App Transport Security (ATS)
Trong `ios/YourApp/Info.plist`, thêm exception cho IP VPS hoặc cho phép tải HTTP:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

### 4. Mẫu Khởi Tạo Axios Instance & Tự Động Refresh Token

```typescript
// src/services/api.ts
import axios from 'axios';

const BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://180.93.120.246:8080';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: Gắn Bearer Token
apiClient.interceptors.request.use((config) => {
  const token = getAccessToken(); // Lấy từ AsyncStorage / SecureStore / Redux
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response Interceptor: Xử lý 401 Silent Refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        const refreshToken = getRefreshToken();
        const res = await axios.post(`${BASE_URL}/api/v1/auth/refresh?refreshToken=${refreshToken}`);
        if (res.data.success) {
          const newAccessToken = res.data.data.accessToken;
          saveAccessToken(newAccessToken);
          originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
          return apiClient(originalRequest);
        }
      } catch (refreshErr) {
        logoutUser(); // Xóa token và redirect về màn login
      }
    }
    return Promise.reject(error);
  }
);
```

---

### 5. Mẫu Kết Nối WebSocket Realtime (STOMP Client)

```typescript
// src/services/websocket.ts
import { Client } from '@stomp/stompjs';

export const initWebSocket = (userId: string, onNotification: (msg: any) => void) => {
  const client = new Client({
    brokerURL: 'ws://180.93.120.246:8080/ws-native', // Dùng cho React Native / Flutter
    // Nếu là Web: webSocketFactory: () => new SockJS('http://180.93.120.246:8080/ws'),
    reconnectDelay: 5000,
    heartbeatIncoming: 10000,
    heartbeatOutgoing: 10000,
    onConnect: () => {
      console.log('Connected to VPS WebSocket');
      client.subscribe(`/topic/users/${userId}/notifications`, (message) => {
        if (message.body) {
          const payload = JSON.parse(message.body);
          onNotification(payload);
        }
      });
    },
    onStompError: (frame) => {
      console.error('Broker error:', frame.headers['message']);
    },
  });

  client.activate();
  return client;
};
```

---

## Response Format chuẩn

```json
{
  "success": true,
  "message": "...",
  "data": { ... },
  "timestamp": "2026-09-02T07:30:00Z",
  "errorCode": null
}
```

Khi lỗi: `"success": false`, `"errorCode": "WALLET_NOT_FOUND"`, `"data": null`

---

## 1. AUTH `/api/v1/auth`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/register` | `{phoneNumber*, fullName*, password*(min6), deviceId}` | `AuthResponse` | 201 Created |
| POST | `/login` | `{phoneNumber*, password*, deviceId}` | `AuthResponse` | Rate limited 10/min |
| POST | `/logout` | Header: `Authorization: Bearer {token}` | `null` | Blacklists access token |
| POST | `/logout/current` | Header: `Authorization: Bearer {token}` | `null` | Alias của logout |
| POST | `/refresh` | `?refreshToken={token}` | `AuthResponse` | Silent refresh |
| POST | `/otp/send` | `?phoneNumber={phone}` | `null` | Rate limited 3/min |
| POST | `/otp/verify` | `?phoneNumber={phone}&otp={6digits}` | `Boolean` | |
| POST | `/forgot-password` | `?phoneNumber={phone}` | `null` | Rate limited 3/min |
| POST | `/reset-password` | `?phoneNumber=&otp=&newPassword=` | `null` | |

**AuthResponse:**
```json
{
  "userId": "uuid",
  "phoneNumber": "0987...",
  "accessToken": "jwt...",
  "refreshToken": "jwt..."
}
```

---

## 2. WALLET `/api/v1/wallets`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/` | `{ownerId*, currency*}` | `WalletResponse` | Tạo ví mới |
| GET | `/me` | — | `WalletResponse` | Auth required, lấy ví của user hiện tại (sau login) |
| GET | `/{walletId}` | — | `WalletResponse` | Auth required, phải là owner |
| GET | `/recipient-info` | `?walletId= hoặc ?phoneNumber=` | `RecipientInfoResponse` | Tra tên masked |
| POST | `/deposit` | `{requestId, walletId*, amount*(>0), currency*}` | `TransferResponse` | Auth required |
| POST | `/transfer/init` | `{requestId*, sourceWalletId*, targetWalletId*, amount*, currency*, bankCode*, note}` | `TransferResponse` (status=PENDING_CONFIRMATION) | Tạo OTP tự động |
| POST | `/transfer/{transactionId}/confirm` | `?otp= hoặc ?pin=` | `TransferResponse` (status=SUCCESS) | Auth + verify OTP/PIN |
| POST | `/transfer/qr/init` | `{requestId, sourceWalletId*, qrCode*, amount, currency*}` | `TransferResponse` | QR transfer |
| POST | `/withdraw` | `{requestId, walletId*, bankAccountId*, amount*, currency*, pinToken*}` | `TransferResponse` | Cần pinToken từ verify PIN |
| GET | `/fees/estimate` | `?type={TRANSFER\|WITHDRAWAL\|TOPUP}&amount=&currency=VND` | `FeeEstimateResponse` | Auth required |
| POST | `/transactions/{transactionId}/reverse` | `?reason=` | `TransferResponse` | Admin/support only |

**WalletResponse:**
```json
{
  "id": "uuid",
  "ownerId": "userId",
  "balance": 1500000.00,
  "currency": "VND",
  "createdAt": "...",
  "updatedAt": "..."
}
```

**RecipientInfoResponse:**
```json
{
  "walletId": "uuid",
  "phoneNumber": "0987...",
  "maskedName": "NGUYEN V** AN",
  "fullName": "NGUYEN VAN AN"
}
```

**TransferResponse** (fields dùng `@JsonInclude(NON_NULL)` — null không xuất hiện trong JSON):
```json
{
  "transactionId": "uuid",
  "requestId": "client-uuid",
  "sourceWalletId": "uuid",
  "targetWalletId": "uuid",
  "amount": 500000.00,
  "currency": "VND",
  "type": "TRANSFER_OUT",
  "status": "SUCCESS",
  "timestamp": "...",
  "note": "Trả tiền ăn",
  "bankCode": "SENHONG",
  "isInternal": true,
  "feeAmount": 0.00,
  "balance": 4500000.00,
  "runningBalance": 4500000.00,
  "senderName": "TRAN THI BINH",
  "senderAccount": "0987654321",
  "recipientName": "NGUYEN VAN AN",
  "recipientAccount": "0912345678",
  "counterpartyName": "NGUYEN VAN AN",
  "counterpartyAccount": "0912345678",
  "counterpartyBankName": "SenHong",
  "originalTransactionId": null
}
```

**Enum `type`:** `TRANSFER_OUT` / `TRANSFER_IN` / `DEPOSIT` / `WITHDRAWAL` / `REVERSAL`
**Enum `status`:** `PENDING_CONFIRMATION` / `SUCCESS` / `FAILED`

> ⚠️ **FE cần biết:**
> - `bankCode = "SENHONG"` = nội bộ, `bankCode = "VCB"/"BIDV"...` = ngoại
> - `balance` là snapshot sender tại lúc commit — dùng để update UI ngay, không cần GET lại ví
> - `balance` của **receiver** không có trong response này — receiver phải gọi `GET /wallets/{id}` riêng nếu cần hiển thị
> - `type` trong history đã được enrich thành `TRANSFER_OUT`/`TRANSFER_IN` theo `walletId` người xem

---

## 3. TRANSACTION HISTORY `/api/v1/transactions`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | `?walletId=*&type={enum}&page=0&size=20` | `List<TransferResponse>` | type tùy chọn: TRANSFER/DEPOSIT/WITHDRAWAL |
| GET | `/{id}` | — | `TransferResponse` | Chi tiết 1 giao dịch |
| GET | `/export/csv` | `?walletId=*&fromDate=&toDate=` | `byte[]` (text/csv) | File download |
| GET | `/export/pdf` | `?walletId=*&fromDate=&toDate=` | `byte[]` (application/pdf) | File download |
| GET | `/export/excel` | `?walletId=*&fromDate=&toDate=` | `byte[]` (.xlsx) | File download |
| GET | `/{id}/receipt.pdf` | — | `byte[]` (application/pdf) | Auth, chỉ owner |

`fromDate`, `toDate` format: ISO-8601 Instant (`2026-01-01T00:00:00Z`)

---

## 4. USER & PROFILE `/api/v1/users`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| GET | `/me` | — | `UserProfile` | Auth required |
| PUT | `/me` | `?fullName=&email=&dob=` | `UserProfile` | @RequestParam, không phải JSON body |
| POST | `/me/avatar` | `?avatarUrl=` | `UserProfile` | |
| GET | `/{id}/public-info` | — | `UserProfile` | Thông tin public của người dùng |
| GET | `/search` | `?phone={phoneNumber}` | `PublicUserProfile` | 404 nếu không tìm thấy |
| POST | `/pin/set` | `{pin*}` (6 chữ số) | `null` | |
| POST | `/pin/verify` | `{pin*}` (6 chữ số) | `String` (pinToken) | Dùng pinToken cho withdraw |
| POST | `/kyc` | `{idCardNumber*, fullName*, dob*, frontCardUrl*, backCardUrl*, selfieUrl*}` | `KycResponse` | |
| GET | `/kyc/status` | — | `KycResponse` | |
| POST | `/kyc/webhook` | `?userId=&status=&reason=` | `KycResponse` | Internal webhook |
| POST | `/change-password` | `?oldPassword=&newPassword=` | `null` | @RequestParam |
| GET | `/me/qrcode` | — | `String` (EMVCo QR string) | QR cá nhân |

**UserProfile:**
```json
{
  "userId": "uuid",
  "fullName": "...",
  "email": "...",
  "dob": "...",
  "avatarUrl": "..."
}
```

**KycResponse:**
```json
{
  "id": "uuid",
  "userId": "uuid",
  "status": "PENDING|VERIFIED|REJECTED",
  "fullName": "...",
  "idCardNumber": "...",
  "frontCardUrl": "...",
  "backCardUrl": "...",
  "selfieUrl": "...",
  "createdAt": "..."
}
```

---

## 5. ACCOUNT `/api/v1/account`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/password/change` | `{oldPassword*, newPassword*(min6)}` | `null` | Auth required |
| POST | `/password/reset` | `?phoneNumber=&otp=&newPassword=` | `null` | Public |
| POST | `/2fa/enable` | — | `null` | |
| POST | `/2fa/disable` | — | `null` | |

---

## 6. SECURITY `/api/v1/security`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| POST | `/biometric/register` | `?biometricToken=` | `null` | Auth required |
| POST | `/biometric/verify` | `?biometricToken=` | `String` (pinToken) | Trả pinToken để dùng cho withdraw |
| GET | `/login-history` | — | `List<Map>` | Auth required |

---

## 7. SESSIONS `/api/v1/sessions`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | — | `List<DeviceSession>` | Auth required |
| DELETE | `/{deviceId}` | — | `null` | Remote logout thiết bị |
| DELETE | `/` | — | `null` | Đăng xuất tất cả thiết bị |
| POST | `/{deviceId}/fcm` | `?fcmToken=` | `null` | Đăng ký FCM token cho thiết bị |

**DeviceSession:**
```json
{
  "deviceId": "...",
  "deviceName": "...",
  "ipAddress": "...",
  "userAgent": "...",
  "lastActiveAt": "..."
}
```

---

## 7.1. DEVICE TOKENS & FCM PUSH `/api/v1/devices`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/register` | `{fcmToken*, deviceType}` | `DeviceToken` | Auth required, lưu/cập nhật token FCM |
| DELETE | `/unregister` | `?fcmToken=` hoặc body `{fcmToken}` | `null` | Gọi khi logout để xóa token khỏi DB |

**Register Request:**
```json
{
  "fcmToken": "c-N6Vq7...fcm_token_string",
  "deviceType": "ANDROID" // "ANDROID" | "IOS"
}
```

**Payload FCM Push (Mobile nhận khi app killed/background):**
- **`notification`**: Hiển thị trên Notification Center của OS
  - `title`: "Biến động số dư: Chuyển tiền"
  - `body`: "TK 0987... GD thành công. PS: -50,000 VND. SD: 950,000 VND - Đến: NGUYEN VAN AN (0912...)"
- **`data`** (Khớp 100% schema WebSocket `NotificationPayload` để FE parse chung 1 hàm):
  ```json
  {
    "transactionId": "uuid",
    "requestId": "client-uuid",
    "type": "TRANSFER_OUT", // TRANSFER_OUT | TRANSFER_IN | DEPOSIT | WITHDRAWAL...
    "status": "SUCCESS",
    "walletId": "uuid",
    "transactionAmount": "50000.00",
    "amount": "50000.00",
    "transactionCurrency": "VND",
    "newBalance": "950000.00",
    "currency": "VND",
    "timestamp": "2026-09-03T03:30:00Z",
    "note": "Trả tiền cà phê",
    "title": "Biến động số dư: Chuyển tiền",
    "body": "..."
  }
  ```

---


## 8. NOTIFICATIONS `/api/v1/notifications`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | `?type={BALANCE\|PROMOTION\|SYSTEM}&page=0&size=20` | `PageResponse<NotificationInfo>` | Auth required |
| PATCH | `/{id}/read` | — | `null` | Đánh dấu đã đọc |
| PATCH | `/read-all` | `?type=` (optional) | `null` | Đọc tất cả |
| PUT | `/settings` | `?transactionEnabled={bool}&promoEnabled={bool}` | `null` | Cài đặt thông báo |

**PageResponse:**
```json
{
  "content": [...],
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5,
  "last": false
}
```

---

## 9. BANK ACCOUNTS `/api/v1/bank-accounts`

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/link` | `{bankCode*, accountNumber*, accountHolderName*}` | `BankAccountResponse` | 201 Created |
| GET | `/` | — | `List<BankAccountResponse>` | Auth required |
| DELETE | `/{bankAccountId}` | — | `null` | |

**BankAccountResponse:**
```json
{
  "id": "uuid",
  "bankCode": "VCB",
  "accountNumber": "10****78",
  "accountHolderName": "...",
  "isDefault": false
}
```

---

## 10. FUNDING SOURCES `/api/v1/funding-sources`

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| GET | `/` | — | `List<FundingSourceResponse>` | Auth required |
| POST | `/link` | `{type*(BANK_ACCOUNT\|CREDIT_CARD\|DEBIT_CARD), provider*, number*(4-20 chars), cardHolderName, expiryDate, cvv}` | `FundingSourceResponse` | Số bị mask khi lưu |
| DELETE | `/{id}` | — | `null` | Soft delete |

---

## 11. BENEFICIARIES `/api/v1/beneficiaries`

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/` | `{beneficiaryWalletId, nickname, bankCode, accountNumber}` | `Beneficiary` | 201 Created |
| GET | `/` | — | `List<Beneficiary>` | Auth required |
| DELETE | `/{id}` | — | `null` | |

---

## 12. BANKS `/api/v1/banks`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | — | `List<BankResponse>` | Public, không cần auth |

**BankResponse:**
```json
{
  "bankCode": "VCB",
  "bankName": "Vietcombank",
  "logoUrl": "...",
  "isInternal": false
}
```

Có sẵn trong hệ thống: `SENHONG` (internal), `VCB`, `TCB`, `BIDV`

---

## 13. PAYMENTS `/api/v1/payments`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/vietqr/generate` | `{bankBin*, accountNumber*, amount, purpose}` | `VietQrPayload` | Sinh QR |
| POST | `/vietqr/decode` | `?qrString=` | `VietQrPayload` | Giải mã QR |
| GET | `/bills/query` | `?billType={ELECTRICITY\|WATER\|INTERNET\|TUITION}&customerCode=` | `Bill` | Tra hóa đơn |
| POST | `/bills/pay` | `{requestId, walletId*, billId*, amount*, currency*}` | `TransferResponse` | Auth required |
| POST | `/topup` | `{requestId, walletId*, phoneNumber*, amount*, currency*}` | `TransferResponse` | Auth required |
| POST | `/qr/scan` | `?qrString=` | `Map<String,Object>` | Parse QR, trả thông tin |

---

## 14. BILLS `/api/v1/bills`

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| GET | `/lookup` | `?type={BillType}&customerCode=` | `Bill` | Public |
| POST | `/pay` | `{requestId, walletId*, billId*, amount*, currency*}` | `Transaction` | Auth required |
| POST | `/topup` | `{requestId, walletId*, phoneNumber*, amount*, currency*}` | `Transaction` | Auth required |

> ⚠️ Trùng chức năng với `/api/v1/payments/bills/pay` và `/payments/topup`. FE nên dùng nhất quán **một** trong hai prefix. Khuyến nghị dùng `/api/v1/bills/`.

---

## 15. MONEY REQUESTS `/api/v1/money-requests`

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/` | `{payerUserId*, amount*(>0), currency*, message}` | `MoneyRequestResponse` | 201 Created, auth required |
| POST | `/{id}/accept` | — | `MoneyRequestResponse` | Payer chấp nhận → thực hiện transfer |
| POST | `/{id}/reject` | — | `MoneyRequestResponse` | Payer từ chối |
| POST | `/{id}/cancel` | — | `MoneyRequestResponse` | Requester hủy |
| GET | `/received` | — | `List<MoneyRequestResponse>` | Yêu cầu nhận (mình là người trả) |
| GET | `/sent` | — | `List<MoneyRequestResponse>` | Yêu cầu đã gửi (mình là người nhận tiền) |
| GET | `/{id}` | — | `MoneyRequestResponse` | Chi tiết 1 request |

---

## 16. CONFIG & LEGAL

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/api/v1/config/limits` | — | `Map` (static limits) | Auth required |
| GET | `/api/v1/config/limits/status` | — | `UserLimitStatus` | Auth required, tính thực tế đã tiêu |
| GET | `/api/v1/legal/terms` | — | `String` | Public |
| POST | `/api/v1/legal/consent` | `?termsVersion=` | `LegalConsent` | Auth required |

**UserLimitStatus:**
```json
{
  "dailyLimit": 100000000,
  "dailySpent": 500000,
  "dailyRemaining": 99500000,
  "monthlyLimit": 500000000,
  "monthlySpent": 2000000,
  "monthlyRemaining": 498000000,
  "kycLevel": "UNVERIFIED"
}
```

---

## 17. SUPPORT `/api/v1/support`

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| POST | `/tickets` | `?subject=&category=GENERAL&initialMessage=` | `SupportTicket` | 201 Created |
| GET | `/tickets` | — | `List<SupportTicket>` | Auth required |
| GET | `/tickets/{id}` | — | `{ticket, messages}` | |
| POST | `/tickets/{id}/messages` | `?content=` | `TicketMessage` | |
| GET | `/faq` | — | `List<{question, answer}>` | Public |

---

## 18. MISC

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| POST | `/api/v1/promotions/redeem` | `?code=` | `Voucher` | Auth required |
| POST | `/api/v1/promotions/apply` | `?code=&orderAmount=` | `Voucher` | Auth required |
| GET | `/api/v1/promotions` | — | `List<Voucher>` | Public |
| GET | `/api/v1/promotions/my-vouchers` | — | `List<Voucher>` | Auth required |
| GET | `/api/v1/referrals/code` | — | `ReferralInfo` | Auth required |
| POST | `/api/v1/referrals/apply` | `?referralCode=` | `null` | Auth required |
| GET | `/api/v1/referrals/history` | — | `List<Map>` | Auth required |
| POST | `/api/v1/feedback` | `?rating={1-5}&comment=` | `AppFeedback` | Auth required |
| POST | `/api/v1/merchants/payments/confirm` | `?walletId=&orderId=` | `TransferResponse` | Auth required |

---

## 19. LEDGER & RECONCILIATION (Internal / Admin)

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/api/v1/ledger/accounts` | `{accountName*, accountType*(ASSET/LIABILITY/...), currency*}` | `LedgerAccount` | 201 Created |
| GET | `/api/v1/ledger/accounts` | — | `List<LedgerAccount>` | |
| GET | `/api/v1/ledger/entries` | — | `List<JournalEntry>` | |
| POST | `/api/v1/reconciliation/run` | — | `Map` (report) | Trigger manual reconciliation |

---

## 20. WEBHOOKS `/api/v1/webhooks` (Public — BE nhận từ đối tác)

| Method | Path | Body / Params | Notes |
|--------|------|---------------|-------|
| POST | `/napas/callback` | `@RequestBody Map` | NAPAS callback |
| POST | `/bank/deposit-notify` | `?walletId=&amount=&bankTxRef=` | Ngân hàng thông báo nạp tiền |
| POST | `/merchants/callback` | `@RequestBody Map` | Merchant callback (stub) |

---

## Luồng chuyển tiền nội bộ — Step-by-step

```
1. GET /api/v1/wallets/recipient-info?phoneNumber=0912345678
   → lấy walletId người nhận + maskedName để hiển thị màn hình xác nhận

2. GET /api/v1/wallets/fees/estimate?type=TRANSFER&amount=500000&currency=VND
   → hiển thị phí (= 0 VND với chuyển khoản nội bộ SENHONG)

3. POST /api/v1/wallets/transfer/init
   Body: {
     "requestId": "client-uuid-v4",
     "sourceWalletId": "uuid",
     "targetWalletId": "uuid",
     "amount": 500000,
     "currency": "VND",
     "bankCode": "SENHONG",
     "note": "Trả tiền ăn"
   }
   → nhận transactionId, status = "PENDING_CONFIRMATION"
   → OTP 6 số được generate và log ra server (mock)

4. POST /api/v1/wallets/transfer/{transactionId}/confirm?otp=123456
   (hoặc ?pin=123456 nếu dùng PIN)
   → nhận TransferResponse với status = "SUCCESS", balance mới của sender

5. WebSocket nhận notification realtime:
   Subscribe: /topic/users/{userId}/notifications
   → cả sender và receiver đều nhận push ngay sau bước 4
```

> ⚠️ **OTP TTL = 5 phút.** Nếu user không confirm trong 5 phút → `/confirm` trả lỗi `INVALID_PIN`. FE phải restart flow từ `/init`.
> ⚠️ **Sai OTP/PIN 3 lần** → user bị lock 15 phút. FE hiển thị thông báo có countdown.
> ⚠️ **OTP là 1-time** (bị xóa sau khi dùng đúng). **PIN không phải 1-time** — có thể dùng lại trong cùng session.

---

## Error Codes chuẩn

| errorCode | HTTP | Mô tả |
|-----------|------|-------|
| `WALLET_NOT_FOUND` | 404 | Ví không tồn tại |
| `INVALID_PIN` | 400 | Sai PIN hoặc OTP |
| `INSUFFICIENT_BALANCE` | 400 | Không đủ số dư |
| `ACCOUNT_LOCKED` | 423 | Tài khoản bị khóa (sai PIN/OTP 3 lần) |
| `LIMIT_EXCEEDED` | 400 | Vượt hạn mức ngày/tháng |
| `VALIDATION_FAILED` | 400 | Dữ liệu đầu vào không hợp lệ |
| `BAD_REQUEST` | 400 | Request không hợp lệ |
| `USER_NOT_FOUND` | 404 | User không tồn tại |
| `INTERNAL_SERVER_ERROR` | 500 | Lỗi server |
| _(không có errorCode)_ | 409 | Optimistic lock conflict — FE retry với exponential backoff |
| _(không có errorCode)_ | 401 | Token hết hạn → trigger silent refresh (`POST /auth/refresh`) |
| _(không có errorCode)_ | 403 | Không có quyền truy cập |

---

## Thứ tự ưu tiên Sprint (dành cho PM/Dev Lead)

| Sprint | Nội dung | Ghi chú |
|--------|----------|---------|
| **Sprint 1** | Auth (Mục 1) + Wallet Core (Mục 2 — GET balance, recipient-info) | Dashboard chạy được, hiển thị số dư |
| **Sprint 2** | Transaction flow (Mục 2 — init/confirm/deposit/withdraw) | Luồng tiền cốt lõi với OTP/PIN |
| **Sprint 3** | Transaction History (Mục 3) + Export | Xem lịch sử, tải sao kê |
| **Sprint 4** | QR & Bills (Mục 12, 13, 14) | Tiện ích mở rộng |
| **Sprint 5** | Security, Sessions, Notifications, Beneficiaries (Mục 6, 7, 8, 11) | Hoàn thiện UX |
| **Sprint 6** | Money Requests, Promotions, Referrals, Support (Mục 15, 17, 18) | Nice-to-have |
