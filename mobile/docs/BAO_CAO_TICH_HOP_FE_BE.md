# BÁO CÁO KỸ THUẬT VÀ ĐẶC TẢ TÍCH HỢP CHO FRONTEND (FE INTEGRATION REPORT)
**Dự án:** Sen Hồng E-Wallet (Fintech App)  
**Ngày lập:** 05/09/2026  
**Người lập:** Backend Engineering Team  
**Đối tượng nhận:** Frontend Team (Flutter / Mobile Devs)

---

## ⚠️ SUPERSEDED — NỘI DUNG DƯỚI ĐÂY LÀ ĐẶC TẢ LỊCH SỬ, KHÔNG PHẢN ÁNH BACKEND COMMIT 75BF273

> **QUAN TRỌNG:** Báo cáo này được viết vào ngày **05/09/2026**, mô tả hợp đồng API **TRƯỚC** khi backend tách microservices (commit `29aba05`, `2475f1d`, `75bf273` hiện tại). Mobile team đã code theo báo cáo này ⇒ dẫn đến **drift nghiêm trọng** (38 endpoint không tồn tại, 7 endpoint sai hợp đồng).
>
> **Để xem hợp đồng thực tế tại commit 75bf273**, xem:
> - `.agents_workspace/01_ISSUES_AND_TASKS.md` — Phụ lục A (Bản đồ endpoint)
> - `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md` — Báo cáo audit cuối
> - `mobile/README.md` — Đã đính chính

---

## MỤC LỤC
1. [Giải đáp & Xác nhận 9 điểm trọng yếu với Backend](#1-giải-đáp--xác-nhận-9-điểm-trọng-yếu-với-backend)
2. [Chi tiết đặc tả tích hợp từng phân hệ (Mục 2 -> 10)](#2-chi-tiết-đặc-tả-tích-hợp-từng-phân-hệ-mục-2---10)
3. [Lộ trình triển khai & Tiêu chí nghiệm thu (Phase 1 + 2 Vertical Slice)](#3-lộ-trình-triển-khai--tiêu-chí-nghiệm-thu)
4. [PHỤ LỤC: HỢP ĐỒNG THỰC TẾ (Tại Commit 75bf273)](#phụ-lục-hợp-đồng-thực-tế-tại-commit-75bf273)

---

## 1. GIẢI ĐÁP & XÁC NHẬN 9 ĐIỂM TRỌNG YẾU VỚI BACKEND

### 1.1. Endpoint Refresh Token
- **Path báo cáo:** `POST /api/v1/auth/refresh?refreshToken={token}` (Query Parameter)
- **Backend thực tế (AuthController.java:41-44):** `POST /api/v1/auth/refresh` với **JSON Body** `@RequestBody RefreshTokenRequest`
- **Trạng thái:** ❌ **SAI** — Mobile gửi query, BE bắt body ⇒ Silent refresh hỏng (MOB-001)

### 1.2. Cấu trúc lỗi chuẩn (Standard Error Structure)
- **Báo cáo:** Toàn bộ API trả `ApiResponse` có `errorCode` + `timestamp`
- **Backend thực tế:** 
  - Identity: có `error` + `timestamp`, **KHÔNG `errorCode`**
  - Payment: **KHÔNG `errorCode`, KHÔNG `timestamp`**
  - Gateway 401: chỉ `error`
- **Trạng thái:** ❌ **SAI** — Mobile parse lỗi phụ thuộc `errorCode` không tồn tại

### 1.3. `walletId` lấy từ đâu sau login?
- **Báo cáo:** `GET /wallets/me` (khuyến nghị) hoặc `GET /wallets/recipient-info?phoneNumber=`
- **Backend thực tế:** Cả hai đều tồn tại ✅

### 1.4. Quy tắc PIN/OTP và Mã Lỗi Giao Dịch
- **Báo cáo:** Có `POST /users/pin/set`, `/users/pin/verify`, OTP 6 số, lockout 3 lần
- **Backend thực tế:** **KHÔNG TỒN TẠI** bất kỳ endpoint PIN/OTP nào (grep `otp|pinHash` = 0)
- **Trạng thái:** ❌ **SAI** — Xác thực PIN/OTP giao dịch là giả lập (MOB-002, BE-REQ-03)

### 1.5. Response chính xác của `POST /api/v1/wallets/transfer/init`
- **Báo cáo:** Endpoint `init` trả `PENDING_CONFIRMATION`, OTP sinh ngầm, rồi `confirm?otp=` hoặc `confirm?pin=`
- **Backend thực tế:** **CHỈ CÓ** `POST /api/v1/payments/transfer` **một bước** (TransferController.java:22). Không có init/confirm.
- **Trạng thái:** ❌ **SAI** — Luồng 2 bước không tồn tại

### 1.6. Binary PDF / Export
- **Báo cáo:** `GET /transactions/{id}/receipt.pdf`, `GET /transactions/export/{csv|pdf|excel}` — Raw binary stream
- **Backend thực tế:** **KHÔNG TỒN TẠI** (TransactionHistoryController chỉ có GET / và GET /{id})
- **Trạng thái:** ❌ **SAI** (BE-REQ-06)

### 1.7. WebSocket: STOMP hay Native WebSocket?
- **Báo cáo:** Bắt buộc STOMP, endpoint `/ws-native`, topic `/topic/users/{userId}/notifications`
- **Backend thực tế:** Gateway route `/ws-native` tồn tại, filter public ✅ (PASS static)

### 1.8. VPS Server & Base URL
- **Báo cáo:** VPS `180.93.120.246:8080`, localhost config
- **Backend thực tế:** Docker compose chỉ có PostgreSQL/Redis/RabbitMQ/Kafka, **KHÔNG CÓ API Gateway container** ⇒ `:8080` không phản hồi

### 1.9. Quyền và Flow Upload Ảnh eKYC
- **Báo cáo:** `POST /users/kyc` nhận JSON với URL ảnh đã upload
- **Backend thực tế:** `POST /kyc/submit`, `GET /kyc/status` (KycController.java:25,35) — **SAI PATH**

---

## 2. CHI TIẾT ĐẶC TẢ TÍCH HỢP TỪNG PHÂN HỆ (MỤC 2 -> 10)

> **Lưu ý:** Tất cả endpoint dưới đây là **theo báo cáo cũ (05/09/2026)**. Hợp đồng thực tế xem Phụ Lục cuối báo cáo.

### Mục 2. Auth + Token Refresh
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| POST | `/auth/register` | `/auth/register` ✅ | ✅ |
| POST | `/auth/login` | `/auth/login` ✅ | ✅ |
| POST | `/auth/refresh?refreshToken=` | `/auth/refresh` (JSON body) | ❌ SAI |
| POST | `/auth/otp/send` | **Không tồn tại** | ❌ BE-REQ-04 |
| POST | `/auth/otp/verify` | **Không tồn tại** | ❌ BE-REQ-04 |
| POST | `/auth/forgot-password` | **Không tồn tại** | ❌ BE-REQ-04 |
| POST | `/auth/reset-password` | **Không tồn tại** | ❌ BE-REQ-04 |
| POST | `/auth/logout` | `/auth/logout` ✅ | ✅ (nhưng mobile không gọi) |

### Mục 3. Home API
| Mục đích | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|----------|-------------------|-----------------|------------|
| Số dư & ví | `GET /wallets/me` | `/wallets/me` ✅ | ✅ |
| User Profile | `GET /users/me` | `/users/me` ✅ | ✅ |
| Hạn mức | `GET /config/limits/status` | **Không tồn tại** | ❌ BE-REQ-06 |
| Giao dịch gần | `GET /transactions?walletId=` | `/transactions` ✅ | ✅ |

### Mục 4. Transfer (Chuyển tiền)
| Bước | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|------|-------------------|-----------------|------------|
| Tra cứu người nhận | `GET /wallets/recipient-info` | `/wallets/recipient-info` ✅ | ✅ |
| Tính phí | `GET /wallets/fees/estimate` | `/wallets/fees/estimate` ✅ | ✅ |
| Khởi tạo | `POST /wallets/transfer/init` | **Không tồn tại** | ❌ BE-GAP |
| Xác nhận | `POST /wallets/transfer/{id}/confirm?otp|pin` | **Không tồn tại** | ❌ BE-GAP |
| **Thực tế** | — | `POST /payments/transfer` (single-step) | ✅ |

### Mục 5. Deposit & Withdraw
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| POST | `/wallets/deposit` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/wallets/withdraw` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/users/pin/verify` (pinToken) | **Không tồn tại** | ❌ BE-REQ-03 |

### Mục 6. Bills / Utilities & QR Code
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| GET | `/bills/lookup` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/bills/pay` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/bills/topup` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/payments/vietqr/decode` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/payments/vietqr/generate` | **Không tồn tại** | ❌ BE-REQ-06 |

### Mục 7. History & Receipt
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| GET | `/transactions` | `/transactions` ✅ | ✅ |
| GET | `/transactions/{id}` | `/transactions/{id}` ✅ | ✅ (nhưng thiếu `walletId` query) |
| GET | `/transactions/{id}/receipt.pdf` | **Không tồn tại** | ❌ BE-REQ-06 |
| GET | `/transactions/export/{csv|pdf|excel}` | **Không tồn tại** | ❌ BE-REQ-06 |

### Mục 8. Profile, Cards & Settings
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| GET | `/users/me` | `/users/me` ✅ | ✅ |
| PUT | `/users/me?fullName&email&dob` | `/users/profile` (JSON body, field `dateOfBirth`) | ❌ SAI PATH/BODY |
| POST | `/users/me/avatar` | **Không tồn tại** | ❌ BE-GAP |
| POST | `/users/kyc` | `/kyc/submit` | ❌ SAI PATH |
| GET | `/users/kyc/status` | `/kyc/status` | ❌ SAI PATH |
| GET | `/bank-accounts` | **Không tồn tại** | ❌ BE-REQ-06 |
| POST | `/bank-accounts/link` | **Không tồn tại** | ❌ BE-REQ-06 |
| GET | `/funding-sources` | **Không tồn tại** | ❌ BE-REQ-06 |
| GET | `/beneficiaries` | **Không tồn tại** | ❌ BE-REQ-06 |
| GET | `/sessions` | `/sessions` ✅ | ✅ (nhưng mobile hardcode giả) |
| DELETE | `/sessions/{id}` | `/sessions/{id}` ✅ | ✅ |
| DELETE | `/sessions` | `/sessions` ✅ | ✅ |

### Mục 9. WebSocket / FCM Push
| Method | Endpoint (Báo Cáo) | Backend Thực Tế | Trạng Thái |
|--------|-------------------|-----------------|------------|
| POST | `/devices/register` | `/devices/register` ✅ | ✅ |
| DELETE | `/devices/unregister` | `/devices/unregister` ✅ | ✅ |

### Mục 10. Xử lý lỗi, Idempotency & UX
| Yêu cầu | Báo Cáo | Backend Thực Tế | Trạng Thái |
|---------|---------|-----------------|------------|
| Idempotency-Key header | Mọi POST biến động số dư | Chỉ payment service đọc body, gateway không check header | ⚠️ PARTIAL |
| 409/429 retry backoff | Tự động retry exponential | **Không có retry/backoff trong DioClient** | ❌ SAI |
| 4 UX state | Loading/Error/Empty/Data | Nhiều màn thiếu empty/error state | ❌ SAI |

---

## 3. LỘ TRÌNH TRIỂN KHAI & TIÊU CHÍ NGHIỆM THU

> Phần này mô tả kế hoạch cũ. Trạng thái thực tế: **CHƯA ĐẠT** do drift backend.

---

## PHỤ LỤC: HỢP ĐỒNG THỰC TẾ (Tại Commit 75bf273)

Dưới đây là danh sách endpoint **THỰC TẾ TỒN TẠI** trong backend tại commit nền `75bf273`, trích xuất từ 18 Controller.java + Gateway routes.

### Auth (Identity Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| POST | `/auth/register` | AuthController:22 | Tạo user + ví mặc định |
| POST | `/auth/login` | AuthController:30 | Rate limit 10/min |
| POST | `/auth/refresh` | AuthController:41 | **JSON Body** `{refreshToken, deviceId?}` |
| POST | `/auth/logout` | AuthController:47 | Blacklist access token |

### User Profile (Identity Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/users/me` | UserController:24 | Profile user hiện tại |
| PUT | `/users/profile` | UserController:32 | **JSON body**: `fullName, email, dateOfBirth` |

### KYC (Identity Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| POST | `/kyc/submit` | KycController:25 | Cần `documentType, documentNumber, frontImageUrl, faceImageUrl...` |
| GET | `/kyc/status` | KycController:35 | Trạng thái KYC |

### Sessions (Identity Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/sessions` | SessionController:24 | Danh sách thiết bị |
| DELETE | `/sessions/{sessionId}` | SessionController:33 | Đăng xuất thiết bị |

### Wallet (Wallet Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/wallets/me` | WalletRestController:43 | Ví của user hiện tại |
| GET | `/wallets/{walletId}` | WalletRestController:56 | ⚠️ **Thiếu ownership check** (BE-001) |
| GET | `/wallets/recipient-info` | WalletRestController:68 | Tra walletId qua phone |
| GET | `/wallets/fees/estimate` | WalletRestController:110 | Ước tính phí |

### Transfer (Payment Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| POST | `/payments/transfer` | TransferController:22 | **Single-step**, nhận `sourceUserId` từ body ⚠️ **IDOR** (BE-001) |

### Transactions (Payment Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/transactions` | TransactionHistoryController:39 | Phân trang, filter walletId/type |
| GET | `/transactions/{id}` | TransactionHistoryController:68 | ⚠️ **Thiếu ownership check**, thiếu `walletId` param |

### Money Requests (Payment Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| POST | `/payments/money-requests` | MoneyRequestController:18 | Body: `requesterId, targetUserId, amount...` |
| POST | `/payments/money-requests/{id}/accept` | MoneyRequestController:55 | Query: `payerUserId` |
| POST | `/payments/money-requests/{id}/reject` | MoneyRequestController:69 | Query: `payerUserId` |
| GET | `/payments/money-requests/user/{userId}` | MoneyRequestController:27 | Received requests |

### Notifications (Notification Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/notifications` | NotificationController:29 | Phân trang |
| PATCH | `/notifications/read-all` | NotificationController:57 | Đánh dấu đã đọc |
| PUT | `/notifications/settings` | NotificationController:66 | Query: `transactionEnabled, promoEnabled` |

### Support (Support Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/support/faq` | SupportController:70 | Public |
| POST | `/support/tickets` | SupportController:31 | Query params |

### Devices (Notification Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| POST | `/devices/register` | DeviceController:27 | FCM token |
| DELETE | `/devices/unregister` | DeviceController:37 | Unregister FCM |

### Promotions (Promotion Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/promotions` | PromotionController:28 | Public |
| GET | `/promotions/my-vouchers` | PromotionController:59 | Auth required |
| POST | `/promotions/redeem` | PromotionController:40 | Query: `code` |
| POST | `/promotions/apply` | PromotionController:49 | Query: `code, orderAmount` |

### Banks (Payment Service)
| Method | Path | Controller | Ghi Chú |
|--------|------|------------|---------|
| GET | `/payments/banks` | BankController:13 | Public, có SENHONG/VCB/TCB/BIDV |

---

## TỔNG KẾT SO SÁNH

| Loại | Số Lượng | Ví Dụ |
|------|----------|-------|
| ✅ Khớp hoàn toàn | 24 | `/auth/login`, `/wallets/me`, `/payments/transfer`... |
| ⚠️ Sai path/payload | 7 | `/users/me` vs `/users/profile`, `/banks` vs `/payments/banks`... |
| ❌ Không tồn tại trong BE | 38 | `/auth/otp/*`, `/users/pin/*`, `/wallets/deposit`, `/bills/*`, `/transactions/export/*`... |

**Tổng:** 69 bề mặt API mobile khai báo (từ `api_constants.dart` + datasource calls).

> Xem chi tiết đầy đủ tại `.agents_workspace/01_ISSUES_AND_TASKS.md` Phụ lục A.