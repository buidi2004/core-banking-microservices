# API Integration Guide — Sen Hồng E-Wallet Backend

> **⚠️ SUPERSEDED — NỘI DUNG DƯỚI ĐÂY LÀ HƯỚNG DẪN LỊCH SỬ (NGÀY 05/09/2026), KHÔNG PHẢN ÁNH BACKEND COMMIT 75BF273**
>
> **Hợp đồng thực tế tại commit 75bf273:** Xem `.agents_workspace/01_ISSUES_AND_TASKS.md` Phụ lục A + `mobile/README.md` (đã đính chính).

---

## 🚨 ĐÍNH CHÍNH VÒNG 2 (2026-10-21 — Con 1, Lead)

| Nội dung | Sự thật hiện tại |
|---|---|
| Hợp đồng API mà tài liệu này mô tả | **LỊCH SỬ (05/09/2026)** — không còn khớp backend. Nguồn sự thật: `mobile/README.md` (đã đính chính) + `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md` |
| Trạng thái backend | 🔴 **ĐÃ BỊ SỬA** — checksum `backend` = `b1338db0…c50e` ≠ baseline `eb378711…003` (vi phạm bất biến dự án). Chi tiết: `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md` |
| Mobile có dùng API backend mới không | ❌ **Chưa** — mọi cờ `BackendCapabilities` vẫn `false` ⇒ 25 màn hình vẫn được gate `showFeatureUnavailable` ⇒ **an toàn cho người dùng** |
| Lệnh kiểm chứng (chỉ đọc) | `bash scripts/check_backend_guard.sh` (exit 0 = sạch, exit 2 = vi phạm) |

> Tài liệu này được giữ lại **chỉ để tham chiếu lịch sử**. **Không dùng làm căn cứ thiết kế hay nghiệm thu.**

---

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

> ⚠️ **Lưu ý:** Docker compose tại commit 75bf273 **KHÔNG CÓ API Gateway container** ⇒ `:8080` không phản hồi. Chỉ có PostgreSQL/Redis/RabbitMQ/Kafka.

---

### 2. Mẫu Cấu hình Biến Môi Trường (`.env`)

#### 📱 React Native (Expo)
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

> ⚠️ **QUAN TRỌNG:** Backend thực tế yêu cầu **JSON Body** cho refresh token, KHÔNG phải query parameter như mẫu cũ dưới đây.

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

// Response Interceptor: Xử lý 401 Silent Refresh (ĐÚNG THEO BE THỰC TẾ)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        const refreshToken = getRefreshToken();
        // BE THỰC TẾ: POST /api/v1/auth/refresh với JSON BODY
        const res = await axios.post(`${BASE_URL}/api/v1/auth/refresh`, {
          refreshToken: refreshToken,
        });
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

## Response Format chuẩn (Backend Thực Tế KHÔNG Thống Nhất)

> ⚠️ **Backend thực tế KHÔNG có envelope thống nhất:**
> - **Identity Service:** có `success`, `message`, `data`, `timestamp` — **KHÔNG `errorCode`**
> - **Payment Service:** `ApiResponse` có `success`, `message`, `data` — **KHÔNG `errorCode`, KHÔNG `timestamp`**
> - **Gateway 401:** chỉ `{ "error": "Unauthorized" }`

```json
{
  "success": true,
  "message": "...",
  "data": { ... },
  "timestamp": "2026-09-02T07:30:00Z",  // Chỉ Identity có
  "errorCode": null                     // Payment KHÔNG CÓ field này
}
```

Khi lỗi: `"success": false`, `"message": "..."`, `"data": null` — **KHÔNG đảm bảo có `errorCode`**.

---

## 1. AUTH `/api/v1/auth` (Backend Thực Tế)

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/register` | `{phoneNumber*, fullName*, password*(min6), deviceId}` | `AuthResponse` | 201 Created, tự tạo ví VND |
| POST | `/login` | `{phoneNumber*, password*, deviceId}` | `AuthResponse` | Rate limited 10/min |
| POST | `/logout` | Header: `Authorization: Bearer {token}` | `null` | Blacklists access token |
| POST | `/refresh` | **JSON Body** `{refreshToken, deviceId?}` | `AuthResponse` | **KHÔNG DÙNG QUERY PARAM** |
| POST | `/otp/send` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-04 |
| POST | `/otp/verify` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-04 |
| POST | `/forgot-password` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-04 |
| POST | `/reset-password` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-04 |

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

## 2. WALLET `/api/v1/wallets` (Backend Thực Tế)

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/` | `{ownerId*, currency*}` | `WalletResponse` | Tạo ví mới |
| GET | `/me` | — | `WalletResponse` | Auth required, ví của user hiện tại |
| GET | `/{walletId}` | — | `WalletResponse` | ⚠️ **Thiếu ownership check** (BE-001) |
| GET | `/recipient-info` | `?walletId= hoặc ?phoneNumber=` | `RecipientInfoResponse` | Tra tên masked |
| GET | `/fees/estimate` | `?type={TRANSFER\|WITHDRAWAL\|TOPUP}&amount=&currency=VND` | `FeeEstimateResponse` | Auth required |
| POST | `/deposit` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| POST | `/transfer/init` | ❌ **KHÔNG TỒN TẠI** | - | BE-GAP (dùng `/payments/transfer`) |
| POST | `/transfer/{transactionId}/confirm` | ❌ **KHÔNG TỒN TẠI** | - | BE-GAP (dùng `/payments/transfer`) |
| POST | `/withdraw` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |

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

---

## 3. TRANSFER `/api/v1/payments` (Backend Thực Tế - Single Step)

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/transfer` | `{sourceUserId*, targetUserId*, amount*, currency*, bankCode*, note?, requestId*}` | `TransferResponse` | **Single-step**, ⚠️ **IDOR: BE không check sourceUserId vs X-User-Id** (BE-001) |

**TransferResponse** (fields `@JsonInclude(NON_NULL)` — null không xuất hiện):
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

---

## 4. TRANSACTION HISTORY `/api/v1/transactions` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | `?walletId=*&type={enum}&page=0&size=20` | `List<TransferResponse>` | type: TRANSFER/DEPOSIT/WITHDRAWAL |
| GET | `/{id}` | — | `TransferResponse` | ⚠️ **Thiếu `walletId` query** ⇒ sai `runningBalance` cho TRANSFER_IN |
| GET | `/export/csv` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/export/pdf` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/export/excel` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/{id}/receipt.pdf` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |

---

## 5. USER & PROFILE `/api/v1/users` (Backend Thực Tế)

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| GET | `/me` | — | `UserProfile` | Auth required |
| PUT | `/profile` | **JSON Body** `{fullName?, email?, dateOfBirth?}` | `UserProfile` | **KHÔNG DÙNG QUERY PARAM**, field `dateOfBirth` (ISO `yyyy-MM-dd`) |
| POST | `/me/avatar` | ❌ **KHÔNG TỒN TẠI** | - | BE-GAP |
| GET | `/{id}/public-info` | — | `UserProfile` | Thông tin public |
| GET | `/search` | `?phone={phoneNumber}` | `PublicUserProfile` | 404 nếu không tìm thấy |
| POST | `/pin/set` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-03 |
| POST | `/pin/verify` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-03 |
| POST | `/kyc` | ❌ **KHÔNG TỒN TẠI** (dùng `/kyc/submit`) | - | SAI PATH |
| GET | `/kyc/status` | ❌ **KHÔNG TỒN TẠI** (dùng `/kyc/status`) | - | SAI PATH |
| POST | `/kyc/submit` | `{documentType*, documentNumber*, frontImageUrl*, backCardUrl?, faceImageUrl*, issuedDate?, issuedPlace?}` | `KycResponse` | **ĐÚNG PATH** |
| GET | `/kyc/status` | — | `KycResponse` | **ĐÚNG PATH** |
| POST | `/change-password` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-04? |
| GET | `/me/qrcode` | ❌ **KHÔNG TỒN TẠI** | - | BE-GAP |

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

---

## 6. KYC `/api/v1/kyc` (Backend Thực Tế)

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/submit` | `{documentType*, documentNumber*, frontImageUrl*, backCardUrl?, faceImageUrl*, issuedDate?, issuedPlace?}` | `KycResponse` | Mobile cũ sai path `/users/kyc` |
| GET | `/status` | — | `KycResponse` | Mobile cũ sai path `/users/kyc/status` |

---

## 7. SESSIONS `/api/v1/sessions` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | — | `List<DeviceSession>` | Auth required |
| DELETE | `/{deviceId}` | — | `null` | Remote logout thiết bị |
| DELETE | `/` | — | `null` | Đăng xuất tất cả thiết bị |
| POST | `/{deviceId}/fcm` | ❌ **KHÔNG TỒN TẠI** | - | BE-GAP |

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

## 8. DEVICE TOKENS & FCM PUSH `/api/v1/devices` (Backend Thực Tế)

| Method | Path | Body / Params | Response `data` | Notes |
|--------|------|---------------|-----------------|-------|
| POST | `/register` | `{fcmToken*, deviceType}` | `DeviceToken` | Auth required |
| DELETE | `/unregister` | `?fcmToken=` hoặc body `{fcmToken}` | `null` | Gọi khi logout |

---

## 9. NOTIFICATIONS `/api/v1/notifications` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | `?type={BALANCE\|PROMOTION\|SYSTEM}&page=0&size=20` | `PageResponse<NotificationInfo>` | Auth required |
| PATCH | `/{id}/read` | — | `null` | Đánh dấu đã đọc |
| PATCH | `/read-all` | `?type=` (optional) | `null` | Đọc tất cả |
| PUT | `/settings` | `?transactionEnabled={bool}&promoEnabled={bool}` | `null` | **QUERY PARAMS** (không phải JSON body) |

---

## 10. MONEY REQUESTS `/api/v1/payments/money-requests` (Backend Thực Tế)

| Method | Path | Body | Response `data` | Notes |
|--------|------|------|-----------------|-------|
| POST | `/` | `{requesterId*, targetUserId*, amount*(>0), currency*, message?, expiresInHours?}` | `MoneyRequestResponse` | Mobile cũ sai: `payerUserId` |
| POST | `/{id}/accept` | — | `MoneyRequestResponse` | Query: `payerUserId` |
| POST | `/{id}/reject` | — | `MoneyRequestResponse` | Query: `payerUserId` |
| POST | `/{id}/cancel` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/user/{userId}` | — | `List<MoneyRequestResponse>` | Received requests |
| GET | `/received` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/sent` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |
| GET | `/{id}` | ❌ **KHÔNG TỒN TẠI** | - | BE-REQ-06 |

---

## 11. PROMOTIONS `/api/v1/promotions` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | — | `List<Voucher>` | Public |
| GET | `/my-vouchers` | — | `List<Voucher>` | Auth required |
| POST | `/redeem` | `?code=` | `Voucher` | Auth required |
| POST | `/apply` | `?code=&orderAmount=` | `Voucher` | Auth required |

---

## 12. BANKS `/api/v1/payments/banks` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| GET | `/` | — | `List<BankResponse>` | Public, có SENHONG/VCB/TCB/BIDV |

> ⚠️ **Mobile cũ dùng `/banks` — SAI PATH**, BE là `/payments/banks`

---

## 13. SUPPORT `/api/v1/support` (Backend Thực Tế)

| Method | Path | Params | Response `data` | Notes |
|--------|------|--------|-----------------|-------|
| POST | `/tickets` | `?subject=&category=GENERAL&initialMessage=` | `SupportTicket` | 201 Created |
| GET | `/tickets` | — | `List<SupportTicket>` | Auth required |
| GET | `/tickets/{id}` | — | `{ticket, messages}` | |
| POST | `/tickets/{id}/messages` | `?content=` | `TicketMessage` | |
| GET | `/faq` | — | `List<{question, answer}>` | Public |

---

## 14. CÁC ENDPOINT KHÔNG TỒN TẠI (BE-GAP / BE-REQ)

Dưới đây là các endpoint **mobile cũ gọi / tài liệu cũ liệt kê** nhưng **KHÔNG TỒN TẠI** trong backend commit 75bf273:

| Nhóm | Endpoint | BE-REQ | Ghi Chú |
|------|----------|--------|---------|
| **Auth OTP** | `/auth/otp/send`, `/auth/otp/verify`, `/auth/forgot-password`, `/auth/reset-password` | BE-REQ-04 | Onboarding hỏng |
| **PIN/OTP Trans** | `/users/pin/set`, `/users/pin/verify`, `/security/biometric/verify` | BE-REQ-03 | Xác thực giả (MOB-002) |
| **Deposit/Withdraw** | `/wallets/deposit`, `/wallets/withdraw` | BE-REQ-06 | 4 màn hình gate |
| **Old Transfer** | `/wallets/transfer/init`, `/wallets/transfer/{id}/confirm` | BE-GAP | Thay bằng `/payments/transfer` |
| **Bills/VietQR** | `/bills/*`, `/payments/vietqr/*`, `/payments/bills/*`, `/payments/topup` | BE-REQ-06 | 7 màn hình gate |
| **Bank Accounts** | `/bank-accounts/*`, `/funding-sources/*` | BE-REQ-06 | 3 màn hình gate |
| **Beneficiaries** | `/beneficiaries/*` | BE-REQ-06 | 1 màn hình gate |
| **Receipt/Export** | `/transactions/{id}/receipt.pdf`, `/transactions/export/{csv|pdf|excel}` | BE-REQ-06 | 2 màn hình gate |
| **Config Limits** | `/config/limits`, `/config/limits/status` | BE-REQ-06 | KYC level screen gate |
| **User Extras** | `/users/me/avatar`, `/users/me/qrcode`, `/users/kyc*`, `/users/change-password` | BE-GAP/REQ-04 | Profile/KYC gate |
| **Money Request** | `/payments/money-requests/received|sent|{id}|cancel` | BE-REQ-06 | Partial support |
| **Referral** | `/referrals/*` | BE-REQ-06 | 1 màn hình gate |
| **Legal/Feedback** | `/legal/*`, `/feedback` | BE-REQ-06 | Gate |
| **Sessions FCM** | `/sessions/{deviceId}/fcm` | BE-GAP | Device mgmt partial |

---

## Error Codes (Backend Thực Tế — KHÔNG Thống Nhất)

| Service | errorCode | HTTP | Mô tả |
|---------|-----------|------|-------|
| Identity | (không có) | 401 | Token hết hạn → trigger silent refresh |
| Identity | (không có) | 400 | Validation failed |
| Payment | (không có) | 400 | INSUFFICIENT_BALANCE, LIMIT_EXCEEDED, VALIDATION_FAILED |
| Payment | (không có) | 404 | WALLET_NOT_FOUND, USER_NOT_FOUND |
| Payment | (không có) | 409 | CONCURRENT_CONFLICT — FE retry exponential backoff |
| Payment | (không có) | 429 | SYSTEM_BUSY — FE retry 1s |
| Gateway | (chỉ `error`) | 401 | Unauthorized |

> ⚠️ **Mobile parse lỗi cũ dùng `errorCode` — SẼ FAIL** vì payment/gateway không trả field này.

---

## Luồng chuyển tiền nội bộ — Step-by-step (Backend Thực Tế)

```
1. GET /api/v1/wallets/recipient-info?phoneNumber=0912345678
   → lấy walletId người nhận + maskedName để hiển thị màn hình xác nhận

2. GET /api/v1/wallets/fees/estimate?type=TRANSFER&amount=500000&currency=VND
   → hiển thị phí (= 0 VND với chuyển khoản nội bộ SENHONG)

3. POST /api/v1/payments/transfer  (SINGLE-STEP, KHÔNG CÓ INIT/CONFIRM)
   Body: {
     "requestId": "client-uuid-v4",
     "sourceUserId": "uuid",        // ⚠️ BE không verify vs X-User-Id (IDOR)
     "targetUserId": "uuid",        // Từ recipient-info.ownerId
     "amount": 500000,
     "currency": "VND",
     "bankCode": "SENHONG",
     "note": "Trả tiền ăn"
   }
   → nhận TransferResponse với status = "SUCCESS", balance mới của sender
   → KHÔNG CÓ OTP/PIN XÁC THỰC SERVER-SIDE (BE-REQ-03)

4. WebSocket nhận notification realtime:
   Subscribe: /topic/users/{userId}/notifications
   → cả sender và receiver đều nhận push ngay sau bước 3
```

> ⚠️ **Mobile hiện tại CHẶN ở bước 3** vì `BackendCapabilities.serverSideTransferAuth = false` (BE-REQ-03).

---

## Thứ tự ưu tiên Sprint (Cập nhật sau Audit)

| Sprint | Nội dung | Ghi chú |
|--------|----------|---------|
| **Sprint 1** | Auth (Login/Register/Refresh/Logout) + Wallet Core (GET balance, recipient-info) | Dashboard chạy được, hiển thị số dư |
| **Sprint 2** | Transfer single-step `/payments/transfer` + Profile update + KYC + Money Requests | Luồng tiền cốt lõi — **CHẶN PIN/OTP** cho đến khi BE có API |
| **Sprint 3** | Transaction History (có `walletId` query) + Sessions thật + Notifications sync | Xem lịch sử, quản lý thiết bị |
| **Sprint 4** | Device Management, Promotions, Support | Hoàn thiện UX |
| **Backend Required** | BE-REQ-01/02 (IDOR), BE-REQ-03 (PIN/OTP), BE-REQ-04 (OTP onboarding), BE-REQ-06 (Deposit/Withdraw/Bills/QR/Accounts/Beneficiaries/Export/Referral/Legal/Feedback) | Cần Backend team triển khai |