# 01_ISSUES_AND_TASKS — KIỂM CHỨNG BÁO CÁO TỐI ƯU HÓA MOBILE & CHUẨN HÓA VỚI BACKEND

| Thuộc tính | Giá trị |
|---|---|
| **Mã tài liệu** | `AUDIT-MOB-BE-001` |
| **Ngày lập** | 2026-10-20 |
| **Người lập** | Con 1 — Lead Agent (Issue Finder & Task Distributor) |
| **Repo** | `core-banking-microservices` |
| **Commit nền** | `75bf273cd707571c13073a625390a78adfa320ce` |
| **Trạng thái** | Hoàn tất khảo sát tĩnh — sẵn sàng giao việc |
| **Ràng buộc bất biến** | **TUYỆT ĐỐI KHÔNG SỬA BẤT KỲ FILE NÀO DƯỚI `backend/`** |
| **Tài liệu thay thế** | `01_PLAN.md` (kế hoạch cũ) — nay được thay bằng tài liệu này |
| **Đầu ra bàn giao** | 3 TASK cho Con 2 / Con 3 / Con 4 + sổ lỗi + bằng chứng |

---

## 0. KẾT LUẬN ĐIỀU HÀNH

### 0.1. Verdict

> **KHÔNG ĐẠT (NOT ALIGNED).** Báo cáo/README của mobile **không phản ánh đúng backend hiện tại** và chứa nhiều tuyên bố không kiểm chứng được hoặc sai sự thật. Không thể dùng báo cáo này làm căn cứ nghiệm thu "mobile chuẩn với BE".

### 0.2. 5 phát hiện quyết định

1. **P0 — Refresh token chắc chắn hỏng:** mobile gửi `refreshToken` qua query, BE bắt buộc `@RequestBody RefreshTokenRequest`. Mọi phiên hết access token sẽ bị đá về đăng nhập. (`mobile/lib/core/network/auth_interceptor.dart:144-147` ↔ `backend/.../AuthController.java:41-44`).
2. **P0 — Xác thực PIN/OTP giao dịch là giả:** backend **không có bất kỳ endpoint PIN/OTP nào**; `confirmTransfer()` bỏ qua tham số `pin` và trả lại kết quả đã lưu. Saga P2P chạy **trước** khi PIN được kiểm tra ⇒ nhập 6 số bất kỳ vẫn chuyển tiền. (`transfer_remote_datasource.dart:96-108`, `confirm_transfer_screen.dart:108-131`).
3. **P0 (BE) — IDOR chuyển tiền:** `POST /payments/transfer` nhận `sourceUserId` từ body và **không đối chiếu `X-User-Id`**; bất kỳ user đăng nhập nào cũng có thể trừ tiền ví người khác nếu biết userId. Tương tự, `GET /wallets/{walletId}` và `GET /transactions/{id}` không kiểm tra quyền sở hữu. **Chỉ ghi nhận, không sửa BE.**
4. **P1 — 38 bề mặt API mobile gọi không tồn tại/sai hợp đồng:** OTP, PIN, deposit, withdraw, bills, VietQR, bank-accounts, funding-sources, beneficiaries, KYC (sai path), limits, receipt/export, referrals, legal, feedback, money-requests (sai base + sai payload). Gateway còn fallback các path này về `http://monolith:8080` — **không có container monolith trong `docker-compose.yml`** ⇒ 503.
5. **P1 — Báo cáo tự mâu thuẫn với code:** README nói `GlassQuality.premium` cho Balance Card/Cards, `contentAwareBrightness` tự động, "6/6 test passed"; thực tế premium chỉ có ở bottom bar, `contentAwareBrightness: false`, và **49 pass / 38 fail** trên 87 test. Các tuyên bố FPS 60/120 **không có bất kỳ phép đo nào**.

### 0.3. Con số baseline (đã chạy lại, không kế thừa báo cáo cũ)

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `flutter analyze` | **No issues found** (1.0s) | Sạch tĩnh |
| `flutter test` | **49 pass / 38 fail / 87 test** | 36 fail thuộc `be_integration_test.dart`, 2 fail thuộc `remote_datasources_test.dart` |
| Backend diff | **0 dòng** | `git status --porcelain -- backend` rỗng |
| Backend checksum | `eb378711...0aa003` | Khớp baseline |
| Backend runtime | **Không chạy** | Chỉ có PostgreSQL/Redis/RabbitMQ/Kafka; gateway `:8080` không phản hồi |
| Thiết bị/profile mode | **Không có** | Không thể đo FPS/startup ⇒ mọi số hiệu năng là UNVERIFIABLE |

---

## 1. PHẠM VI, NGUỒN CHUẨN & PHƯƠNG PHÁP

### 1.1. Ràng buộc cứng

1. **CẤM** `edit`/`write`/`git apply` vào `backend/**`, `docker-compose.yml`, `deploy/**`.
2. **CẤM** chạy migration/DDL/DML, đổi API contract, thêm endpoint giả ở BE.
3. Mọi thay đổi **chỉ được phép** trong `mobile/**`, `.agents_workspace/**` và tài liệu mobile.
4. Trước/sau **mỗi task** phải chạy backend guard (Phụ lục C). Nếu phát hiện backend bị đổi: **dừng ngay**, báo Lead, không tự revert.
5. Không được "sửa test để né fail" bằng cách xóa assertion; chỉ được đánh dấu e2e opt-in hoặc cập nhật theo hợp đồng BE thật.

### 1.2. "Báo cáo" được kiểm chứng là gì?

Khảo sát toàn repo **không tìm thấy file báo cáo tối ưu hóa mobile độc lập** (đã tìm `.agents_workspace/`, `mobile/docs/`, `docs/`, root, các `.md`). Vì vậy audit này kiểm chứng **tập tuyên bố đang được dùng làm báo cáo**:

| Nguồn | Vai trò | Ghi chú |
|---|---|---|
| `mobile/README.md` | Báo cáo "điểm nổi bật kiến trúc/UI/tối ưu" | 12 tuyên bố được trích |
| `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md` | Đặc tả tích hợp FE–BE do BE Team cung cấp | 13 nhóm tuyên bố |
| `mobile/docs/BAO_CAO_KIEM_TRA_LUONG_NUT_BAM.md` | Báo cáo "51/51 màn hình, không thiếu luồng" | 1 tuyên bố tổng |
| `mobile/docs/API_INTEGRATION_GUIDE.md` | Hướng dẫn API (nguồn gây lệch) | Đối chiếu phụ |
| Code mobile hiện tại | Bằng chứng thực thi | `file:line` |

> Nếu user có file báo cáo tối ưu hóa khác, chỉ cần bổ sung vào mục 3; kết luận P0/P1 của tài liệu này **không thay đổi** vì đã đối chiếu trực tiếp code hai phía.

**Vì sao lệch:** `BAO_CAO_TICH_HOP_FE_BE.md` đề ngày **05/09/2026**, trong khi backend đã qua các commit tái cấu trúc gần đây (`29aba05` tách monorepo, `2475f1d` sửa payment saga/outbox, `75bf273` hiện tại). Báo cáo mô tả hợp đồng **trước** khi tách microservices, còn mobile vẫn code theo báo cáo ⇒ drift. Đây là nguyên nhân gốc của phần lớn lỗi P1.

### 1.3. Thứ tự nguồn chuẩn (Source of Truth)

1. **Mã nguồn backend tại commit nền** (annotation `@RequestMapping`, DTO, filter gateway, `docker-compose.yml`).
2. Mã nguồn mobile hiện tại.
3. Tài liệu — **chỉ sau** khi đã đối chiếu code.

### 1.4. Phương pháp

- Trích xuất toàn bộ endpoint từ 18 `*Controller.java` + gateway routes + security filter.
- Trích xuất toàn bộ hằng endpoint mobile (`api_constants.dart`) và nơi gọi thực tế (datasource/screen).
- Chạy `flutter analyze`, `flutter test` (JSON reporter) để lấy baseline chính xác.
- Đo "hiệu năng" bằng **đếm serial HTTP round-trip trong code**, không suy đoán FPS.
- Không chạy API mutation, không chạy stack backend để tránh thay đổi dữ liệu.

---

## 2. BASELINE & BẰNG CHỨNG

Lưu tại `.agents_workspace/evidence/`:

| File | Nội dung |
|---|---|
| `00_baseline_env.txt` | Commit, phiên bản Flutter/Dart, thời điểm |
| `01_backend_guard.txt` | `git status`, `git diff`, checksum backend |
| `02_backend_endpoints.txt` | Inventory endpoint BE từ source |
| `03_mobile_api_constants.txt` | Toàn bộ hằng API mobile kèm số dòng |
| `04_flutter_checks.txt` | Kết quả analyze + test summary |

> **Ghi chú minh bạch:** trong quá trình khảo sát, indexer `codebase-memory` tự động làm mới 2 file cache `backend/.codebase-memory/artifact.json` và `graph.db.zst` (16:07). Đây **không phải mã nguồn** và **không do agent chỉnh sửa**; đã được khôi phục về `HEAD`. Sau khôi phục: `git status --porcelain -- backend` rỗng, checksum khớp baseline. Không có file source nào dưới `backend/` bị thay đổi.

**Test fail theo file:**

| File | Fail | Bản chất |
|---|---:|---|
| `test/be_integration_test.dart` | 36 | E2E gọi backend thật, backend không chạy + 20+ endpoint không tồn tại |
| `test/remote_datasources_test.dart` | 2 | Test kỳ vọng hợp đồng cũ `/wallets/transfer/init` và `confirm`; code đã đổi sang `/payments/transfer` |

---

## 3. ĐỐI CHIẾU TUYÊN BỐ (CLAIM VERIFICATION)

### 3.1. `mobile/README.md`

| ID | Tuyên bố | Bằng chứng thực tế | Verdict |
|---|---|---|---|
| C-01 | Clean Architecture (domain/usecase/repository/BLoC) | `mobile/lib` **không có** `domain/usecases`, `domain/repositories`, `data/repositories`, `presentation/bloc`; `flutter_bloc` khai báo nhưng **0 lần dùng**; 47 file presentation import trực tiếp datasource | **FAIL** |
| C-02 | Balance Card & Virtual Card dùng `GlassQuality.premium` | `grep "GlassQuality.premium"` chỉ có **1** kết quả: `floating_glass_bottom_bar.dart:214`; `balance_card.dart` không set quality; `cards_screen.dart` dùng `minimal/standard` (`:297,540,772`) | **FAIL** |
| C-03 | TransactionHistory dùng `minimal`, cuộn 60/120 FPS | `minimal` đúng (`transaction_history_screen.dart:449`); **không có** profile trace, `integration_test`, benchmark hay thiết bị | **PARTIAL / FPS UNVERIFIABLE** |
| C-04 | MainTabs `contentAwareBrightness` tự động | Code set `contentAwareBrightness: false` (`main_tabs_screen.dart:28`) | **FAIL** |
| C-05 | StatefulShellRoute giữ trạng thái 5 tab | `StatefulShellRoute` tồn tại (`app_router.dart:166`); `MainTabsScreen` dùng `StatefulNavigationShell` | **PASS (static)** |
| C-06 | `run.sh` tự reverse ADB 8080 | `mobile/run.sh:69-74, 196-207` | **PASS** |
| C-07 | Saga P2P qua `POST /payments/transfer` | Đúng endpoint (`api_constants.dart:33`), nhưng **3 RTT/lần chuyển** (2× `GET /wallets/{id}` + POST) | **PARTIAL** |
| C-08 | "Xác nhận an toàn qua PIN/OTP" | BE **không có** endpoint PIN/OTP; `confirmTransfer` bỏ qua `pin`/`otp`; saga chạy trước khi nhập PIN | **FAIL (P0)** |
| C-09 | WebSocket STOMP `/ws-native`, topic đúng BE | Gateway route `/ws-native` (`application.yml`), filter public (`JwtAuthenticationFilter.java:59-65`), topic `api_constants.dart:8-9` | **PASS (static)**; runtime chưa kiểm |
| C-10 | Token/PIN lưu `flutter_secure_storage` | `app_secure_storage.dart` dùng secure storage | **PASS** |
| C-11 | "QA Tests 6/6 Passed" | Thực tế **49/87 pass**, 38 fail | **FAIL** |
| C-12 | "51/51 màn hình, không thiếu luồng" | Đủ route nhưng nhiều màn gọi endpoint không tồn tại hoặc mô phỏng `Future.delayed` (quick loan, live chat, config…) | **FAIL** |

### 3.2. `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md`

| ID | Tuyên bố của báo cáo | Backend thực tế | Verdict |
|---|---|---|---|
| R-01 | Refresh: `POST /auth/refresh?refreshToken=` (query) | `@RequestBody RefreshTokenRequest` (`AuthController.java:41-44`) | **FAIL** |
| R-02 | Error envelope thống nhất có `errorCode` + `timestamp` | identity có `error`/`timestamp`, **không `errorCode`**; payment **không `errorCode`, không `timestamp`**; gateway 401 chỉ `error` | **FAIL** |
| R-03 | `POST /wallets/transfer/init` → `PENDING_CONFIRMATION`, rồi `/{id}/confirm?pin|otp` | Chỉ có `POST /api/v1/payments/transfer` một bước; không có init/confirm (`WalletRestController` chỉ GET; `TransferController.java:22`) | **FAIL** |
| R-04 | PIN: `/users/pin/set`, `/users/pin/verify` → `pinToken`; lockout 3 lần | **Không tồn tại** trong toàn bộ backend (grep `otp|pinHash` = 0) | **FAIL** |
| R-05 | Receipt/export: `/transactions/{id}/receipt.pdf`, `/transactions/export/{csv|pdf|excel}` | `TransactionHistoryController` chỉ có `GET /`, `GET /{id}` | **FAIL** |
| R-06 | Deposit/Withdraw: `/wallets/deposit`, `/wallets/withdraw` | Không tồn tại; chỉ có cash-desk `/cash/deposits` (maker-checker, không phải user deposit) | **FAIL** |
| R-07 | Bills/VietQR: `/bills/*`, `/payments/vietqr/*` | Không tồn tại | **FAIL** |
| R-08 | Profile: `PUT /users/me?fullName&email&dob` | `PUT /users/profile` + JSON body, field `dateOfBirth` (`UserController.java:32-36`) | **FAIL** |
| R-09 | `GET/DELETE /sessions` quản lý thiết bị | BE có (`SessionController.java:24,33`) nhưng mobile **hardcode thiết bị giả** (`device_management_screen.dart:25-120`) | **FAIL (mobile)** |
| R-10 | FCM `POST /devices/register`, `DELETE /devices/unregister` | Khớp (`DeviceController.java:27,37`) | **PASS** |
| R-11 | Mọi POST biến động số dư gửi header `Idempotency-Key` | Interceptor chỉ gắn cho path legacy (`idempotency_interceptor.dart:7-13`); P2P gửi key trong **body**; BE đọc body | **PARTIAL** |
| R-12 | 409/429 tự retry exponential backoff, đủ 4 UX state | Không có retry/backoff trong `DioClient`; nhiều màn không có empty/error state | **FAIL** |
| R-13 | KYC upload/limits/bank-accounts/funding-sources/beneficiaries | Không tồn tại (KYC có `/kyc/submit|status` nhưng mobile gọi sai path) | **FAIL** |

### 3.3. Kết luận claim

- **PASS:** 4 (C-05, C-06, C-09 static, C-10, R-10).
- **FAIL:** 20+. **UNVERIFIABLE:** 1 (FPS).
- Báo cáo không đủ điều kiện nghiệm thu; cần **đính chính công khai** (TASK_CON4).

---

## 4. SỔ LỖI (ISSUE REGISTER)

Mức độ: **P0** = chặn phát hành/mất tiền/mất bảo mật; **P1** = hỏng luồng nghiệp vụ chính; **P2** = sai dữ liệu/hiệu năng/khả năng bảo trì; **P3** = tài liệu/nợ kỹ thuật.

### 4.1. P0 — Bắt buộc xử lý trước mọi việc khác

#### MOB-001 — Refresh token sai định dạng request
- **Owner:** Con 2
- **Bằng chứng:** `mobile/lib/core/network/auth_interceptor.dart:144-147` gửi `queryParameters`; `backend/services/identity-service/.../AuthController.java:41-44` yêu cầu `@Valid @RequestBody RefreshTokenRequest`; DTO `RefreshTokenRequest.java` có `@NotBlank refreshToken`.
- **Tác động:** Không thể silent refresh. Khi access token hết hạn (mặc định ngắn), mọi request 401 → refresh thất bại → xóa token → logout. Người dùng mất phiên giữa giao dịch.
- **Fix (mobile-only):** Gửi JSON body `{refreshToken, deviceId?}`; parse `data.accessToken ?? data.token`; không retry vô hạn; khi refresh fail thì clear session + điều hướng login.
- **Nghiệm thu:** Unit test với `MockDio` xác nhận `RequestOptions.data` là Map chứa `refreshToken` và `queryParameters` rỗng.

#### MOB-002 — Xác thực PIN/OTP giao dịch là giả lập
- **Owner:** Con 3
- **Bằng chứng:** `transfer_remote_datasource.dart:96-108` bỏ qua `pin`/`otp`, trả `_completedTransfers[transactionId]`; `confirm_transfer_screen.dart:108-131` gọi `initTransfer` (saga chạy ngay, trừ tiền) **trước** rồi mới `confirmTransfer`; `transfer_confirm_screen.dart:84-91` tương tự.
- **Tác động:** Bất kỳ 6 chữ số nào cũng chuyển tiền; không có lockout, không OTP; tuyên bố "bảo mật cấp ngân hàng" sai. Đây là lỗi bảo mật nghiêm trọng nhất của mobile.
- **Ràng buộc:** BE không có endpoint PIN/OTP ⇒ **không thể xác thực server-side**. Không được tiếp tục giả lập.
- **Fix (mobile-only):** Đặt cờ `BackendCapabilities.serverSideTransferAuth = false`; **chặn trước khi gọi saga** và hiển thị dialog giải thích "Backend chưa cung cấp API xác thực PIN/OTP — giao dịch tạm khóa để bảo vệ tài khoản". Khi BE bổ sung, bật cờ và gọi endpoint thật. Ghi BE-REQ-01.
- **Nghiệm thu:** Không còn đường code nào chạy `POST /payments/transfer` khi cờ = false; widget test xác nhận dialog chặn; tài liệu không còn claim PIN/OTP.

#### MOB-003 — Onboarding OTP/PIN đi vào ngõ cụt
- **Owner:** Con 2
- **Bằng chứng:** `api_constants.dart:19-25` (`/auth/otp/send`, `/auth/otp/verify`, `/auth/forgot-password`, `/auth/reset-password`, `/users/pin/set`, `/users/pin/verify`); BE `AuthController` chỉ có register/login/refresh/logout, `UserController` chỉ có `/me`, `/profile`.
- **Tác động:** Đăng ký xong → OTP fail → không thể tới Home; quên mật khẩu/PIN không hoạt động; đổi PIN gọi endpoint không tồn tại.
- **Fix (mobile-only):** Sau register, BE đã trả token + tạo ví ⇒ điều hướng **thẳng** Home (bỏ bước OTP/PIN bắt buộc); màn Set PIN/Change PIN hiển thị trạng thái "chưa hỗ trợ" thay vì báo thành công; Forgot Password hướng dẫn liên hệ hỗ trợ. Không gọi endpoint không tồn tại.
- **Nghiệm thu:** Luồng register → Home chạy được; không còn SnackBar "thành công" giả; các màn bị khóa hiển thị lý do rõ ràng.

#### BE-001 — IDOR trên API chuyển tiền & đọc ví/giao dịch (BE-only)
- **Owner:** Backend team — **Con 2/3/4 KHÔNG ĐƯỢC SỬA**
- **Bằng chứng:** `TransferController.java:22-31` nhận `sourceUserId` từ body, không so với `X-User-Id`; `WalletRestController.java:56` `GET /{walletId}` không kiểm tra owner; `TransactionHistoryController.java:68` `GET /{id}` không kiểm tra owner; `MoneyRequestController` nhận `requesterId` từ body.
- **Tác động:** Trừ tiền ví người khác; đọc số dư/lịch sử người khác.
- **Hành động:** Ghi nhận **BE-REQ-01/02** (mục 5), không thực thi. Mobile không thể vá.

### 4.2. P1 — Hỏng luồng nghiệp vụ chính

| ID | Lỗi | Bằng chứng | Owner | Fix mobile-only |
|---|---|---|---|---|
| **MOB-004** | Cập nhật hồ sơ sai method/path/body | `profile_remote_datasource.dart:65-67` gọi `PUT /users/me?fullName&email&dob`; BE `PUT /users/profile` JSON, field `dateOfBirth` (`UserController.java:32`) | Con 2 | Đổi path/body; map `dob` → `dateOfBirth` (ISO `yyyy-MM-dd`); bỏ fallback im lặng |
| **MOB-005** | KYC sai path & payload | `api_constants.dart:64-65` `/users/kyc`, `/users/kyc/status`; BE `/kyc/submit`, `/kyc/status`; payload BE cần `documentType, documentNumber, frontImageUrl, faceImageUrl...` | Con 2 | Sửa constants + payload; gate màn KYC nếu BE chưa có upload ảnh |
| **MOB-006** | Money request sai base/path/payload | `api_constants.dart:88-94` `/money-requests*`; BE `/payments/money-requests`; create cần `{requesterId,targetUserId,amount,expiresInHours,note}` nhưng mobile gửi `payerUserId`; accept/reject cần `?payerUserId` | Con 2 | Sửa base + create payload; list dùng `/user/{userId}`; accept/reject thêm query; detail/cancel chưa có → gate |
| **MOB-007** | ~30 endpoint không tồn tại vẫn được gọi | Deposit/withdraw, bills, VietQR, bank-accounts, funding-sources, beneficiaries, referral, legal, feedback, limits, avatar, receipt/export (xem Phụ lục A) | Con 2 (identity/content) + Con 3 (money/utility) | Gate bằng `BackendCapabilities` + dialog; **không** hiển thị thành công giả |
| **MOB-008** | Quản lý thiết bị hardcode | `device_management_screen.dart:25-120` tạo Samsung/iPhone/iPad + lịch sử đăng nhập giả; revoke chỉ xóa list local | Con 2 | Dùng `GET /sessions`, `DELETE /sessions/{id}`; empty/error state; không bịa dữ liệu |
| **MOB-009** | Logout không gọi BE, không hủy FCM | `more_screen.dart:189-200`, `side_menu_drawer.dart:240-249` chỉ xóa storage; BE có `/auth/logout` + Redis blacklist | Con 2 | Gọi `POST /auth/logout?deviceId=` trước khi xóa; gọi `unregisterDeviceFromBackend()`; best-effort nếu lỗi mạng |
| **MOB-010** | Cài đặt thông báo chỉ lưu local | `notification_settings_screen.dart:53-100` dùng `SharedPreferences`, báo "lưu thành công"; BE có `PUT /notifications/settings?transactionEnabled&promoEnabled` | Con 2 | Sync 2 cờ BE hỗ trợ; các cờ còn lại ghi rõ "chỉ áp dụng trên thiết bị" |
| **MOB-011** | Logger bật vô điều kiện ở release | `dio_client.dart:26-31` `PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true)` | Con 3 | Tắt khi `kReleaseMode`; redact `Authorization`; chỉ log metadata |
| **MOB-012** | README/tài liệu tuyên bố sai | README `:7,18-20,24,28-29`; báo cáo FE-BE `R-01..R-13`; báo cáo nút bấm `51/51` | Con 4 | Đính chính, gắn nhãn "historical/superseded", thêm bảng hợp đồng thật |
| **MOB-013** | Test suite đỏ & e2e không opt-in | 49/87 pass; `be_integration_test.dart` gọi backend thật; `remote_datasources_test.dart:259,284` kỳ vọng endpoint cũ | Con 4 | Tách e2e có tag + skip mặc định; cập nhật test theo BE thật; contract test đọc controller BE (read-only) |

### 4.3. P2 — Dữ liệu/hiệu năng/bảo trì

| ID | Lỗi | Bằng chứng | Owner |
|---|---|---|---|
| **MOB-014** | Mỗi giao dịch P2P tốn 3 RTT (thừa 2 GET) | `transfer_remote_datasource.dart:73-74` gọi `_ownerIdOfWallet` 2 lần, dù `recipientInfo` đã trả `ownerId` và session đã có `userId` | Con 3 |
| **MOB-015** | Chi tiết giao dịch mất góc nhìn ví | `transaction_remote_datasource.dart:69-73` không truyền `walletId`; BE mặc định `sourceWalletId` (`TransactionHistoryController.java:68-75`) ⇒ giao dịch nhận hiển thị như chuyển đi, sai `runningBalance` | Con 3 |
| **MOB-016** | 19 `DioClient()` riêng biệt | `grep "DioClient()"` = 19; mỗi instance có interceptor + connection pool riêng, không tái dùng kết nối | Con 3 |
| **MOB-017** | Idempotency key không ổn định khi retry; map confirm không giới hạn | `transfer_remote_datasource.dart:84-85` sinh key mới mỗi lần; `_completedTransfers` không xóa/không giới hạn (`:10,91`) | Con 3 |
| **MOB-018** | Parse lỗi phụ thuộc `errorCode` không tồn tại | `auth_interceptor.dart:57-70` đọc `errorCode`; payment/gateway không trả field này; phân loại business-401 bằng heuristic path | Con 3 (network) / Con 2 (auth) |
| **MOB-019** | Hai màn xác nhận chuyển tiền trùng chức năng, hành vi khác nhau | `confirm_transfer_screen.dart` (PIN numpad) vs `transfer_confirm_screen.dart` (OTP text) — cả hai gọi init/confirm; router map 2 route (`app_router.dart:323,340`) | Con 3 |
| **MOB-020** | Ảnh không cache, tải lại mỗi lần | `avatar_picker_sheet.dart:326`, `glass_over_image.dart:157`, `user_avatar_widget.dart:187` dùng `Image.network`; không có `cached_network_image` | Con 3 (optional) |
| **MOB-021** | Không có `sendTimeout`, không retry/backoff dù báo cáo tuyên bố | `dio_client.dart:14-15` chỉ connect/receive 15s; báo cáo R-12 | Con 3 |
| **MOB-022** | Khởi động chặn first frame | `main.dart:13-16` `await UserAvatarNotifier.init()` + `await LiquidGlassWidgets.initialize()` trước `runApp` | Con 3 (đo, không mặc định sửa) |

### 4.4. P3 — Nợ kiến trúc/tài liệu

| ID | Lỗi | Bằng chứng | Owner |
|---|---|---|---|
| **MOB-023** | Không có repository/usecase/BLoC; UI gọi datasource trực tiếp | 47 file presentation chứa `RemoteDataSource`; `flutter_bloc` 0 usage | Con 4 (ghi nhận, không refactor lớn) |
| **MOB-024** | `API_INTEGRATION_GUIDE.md` mô tả endpoint không tồn tại | `:220,298,457,524,561,639` | Con 4 |
| **BE-002** | Gateway fallback tới monolith không tồn tại | `application.yml:262-263` (`http://monolith:8080`); `docker-compose.yml` không có service `monolith` ⇒ 503 | Ghi nhận |
| **BE-003** | Envelope lỗi không thống nhất | payment `ApiResponse` không `errorCode/timestamp`; identity dùng `error`; gateway chỉ `error` | Ghi nhận |
| **BE-004** | `GET /payments/transfer/{id}` trả HTTP 200 + `success=false` | `TransferController.java:31-34` | Ghi nhận |
| **BE-005** | Không kiểm tra quyền sở hữu khi đọc ví/giao dịch | `WalletRestController.java:56`; `TransactionHistoryController.java:68` | Ghi nhận |

---

## 5. KHOẢNG TRỐNG BACKEND — CHỈ GHI NHẬN, KHÔNG SỬA

> Mục này là **yêu cầu thay đổi backend (BE change request)**. Con 2/3/4 **tuyệt đối không thực thi**.

| ID | Đề xuất | Lý do | Mức |
|---|---|---|---|
| **BE-REQ-01** | `POST /payments/transfer` phải lấy `sourceUserId` từ `X-User-Id` (gateway) hoặc verify khớp; cấm client chỉ định nguồn tiền | Chặn IDOR trừ tiền ví khác | P0 |
| **BE-REQ-02** | Thêm ownership check cho `GET /wallets/{id}`, `GET /transactions/{id}`, `GET /transactions` (`walletId` phải thuộc `X-User-Id`) | Chặn đọc dữ liệu người khác | P0 |
| **BE-REQ-03** | Bổ sung API PIN/OTP giao dịch thật (`/users/pin/set`, `/users/pin/verify`, xác thực trong saga) + lockout | Mobile không thể tự xác thực an toàn | P0 |
| **BE-REQ-04** | Bổ sung OTP/forgot/reset password hoặc chấp nhận luồng register không OTP chính thức | Onboarding hiện hỏng | P1 |
| **BE-REQ-05** | Thống nhất `ApiResponse` toàn hệ (success/message/data/errorCode/timestamp) | Mobile parse lỗi không ổn định | P1 |
| **BE-REQ-06** | Cung cấp deposit/withdraw user-level, bills, VietQR, bank-accounts, funding-sources, beneficiaries, receipt/export, config/limits, referrals, legal, feedback — hoặc xác nhận cắt khỏi scope | ~25 màn hình không có backend | P1 |
| **BE-REQ-07** | Sửa `monolith-fallback` (bỏ route hoặc thêm service) để trả 404 rõ ràng thay vì 503 | Lỗi mạng khó chẩn đoán | P2 |
| **BE-REQ-08** | `GET /payments/transfer/{id}` trả 404/501 thay vì 200 + success=false | Sai ngữ nghĩa HTTP | P3 |

---

## 6. CƠ HỘI TỐI ƯU MOBILE-ONLY (CÓ THỂ LÀM NGAY)

| ID | Tối ưu | Hiện tại | Sau tối ưu | Cơ sở |
|---|---|---|---|---|
| OPT-01 | Giảm RTT chuyển tiền | 2× `GET /wallets/{id}` + 1× `POST /payments/transfer` = **3 RTT** (chưa kể recipient-info) | **1 RTT** nếu dùng `userId` trong session + `ownerId` từ `recipient-info` đã gọi trước đó | Đếm call trong `transfer_remote_datasource.dart:73-87` |
| OPT-02 | Dùng 1 Dio singleton | 19 instance ⇒ 19 interceptor chain + pool riêng | 1 instance, connection reuse, dễ test | `grep "DioClient()"` |
| OPT-03 | Tắt logger ở release | Log body/header (có thể lộ token/PII), tốn CPU/IO | Không log body ở release | `dio_client.dart:26` |
| OPT-04 | Timeout gửi | Không có `sendTimeout` ⇒ treo tới 15s | Thêm 15s; fail fast | `dio_client.dart:14-15` |
| OPT-05 | Cache avatar | `Image.network` tải lại mỗi lần mở | `cached_network_image` hoặc `cacheWidth` + memory cache | 3 widget |
| OPT-06 | Bỏ đọc prefs lặp | Mỗi thao tác `SharedPreferences.getInstance()` + tạo datasource mới | Inject singleton | nhiều screen |
| OPT-07 | Không chặn first frame | `await` 2 tác vụ trước `runApp` | Chạy song song hoặc sau frame đầu; đo cold start trước/sau | `main.dart:13-16` |

> **Không được** ghi các con số "giảm 40% CPU", "60/120 FPS" nếu chưa đo bằng profile mode trên thiết bị thật. Mọi tối ưu phải kèm log trước/sau hoặc ghi rõ "ước tính".

---

## 7. PHÂN CÔNG CÔNG VIỆC

### 7.0. Quy tắc chung cho cả 3 Con

1. **BACKEND READ-ONLY TUYỆT ĐỐI.** Không sửa `backend/**`, `docker-compose.yml`, `deploy/**`. Chỉ đọc.
2. Trước khi bắt đầu và sau khi kết thúc:
   ```bash
   git status --porcelain -- backend        # phải rỗng
   git diff --name-only -- backend          # phải rỗng
   git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
   # kỳ vọng: eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003
   ```
3. **Không revert** thay đổi có sẵn của người dùng (`mobile/pubspec.lock` đang dirty).
4. Không tạo endpoint/JSON giả để "cho qua" test. Không hardcode dữ liệu tài chính.
5. Mọi kết luận phải kèm `file:line`; không suy đoán endpoint không có annotation.
6. Chỉ sửa file trong **vùng sở hữu** của mình (bảng 7.1). Cần sửa file ngoài vùng → báo Lead.
7. Không thêm dependency mới nếu chưa được Lead duyệt (trừ `cached_network_image` là optional, có ghi chú).
8. Sau khi xong: cập nhật `.agents_workspace/` bằng báo cáo ngắn `02_CON2_REPORT.md` / `03_CON3_REPORT.md` / `04_CON4_REPORT.md`.

### 7.1. Ma trận sở hữu file (chống conflict)

| Vùng | Con 2 | Con 3 | Con 4 |
|---|---|---|---|
| `mobile/lib/core/constants/api_constants.dart` | **OWN** | read-only | read-only |
| `mobile/lib/core/constants/backend_capabilities.dart` (mới) | **OWN** | import | read-only |
| `mobile/lib/presentation/widgets/feature_unavailable.dart` (mới) | **OWN** | import | read-only |
| `mobile/lib/core/network/auth_interceptor.dart` | **OWN** | — | — |
| `mobile/lib/core/network/dio_client.dart` | — | **OWN** | — |
| `mobile/lib/core/network/idempotency_interceptor.dart` | — | **OWN** | — |
| `mobile/lib/data/datasources/remote/auth_remote_datasource.dart` | **OWN** | — | — |
| `mobile/lib/data/datasources/remote/profile_remote_datasource.dart` | **OWN** | — | — |
| `mobile/lib/data/datasources/remote/money_request_remote_datasource.dart` | **OWN** | — | — |
| `mobile/lib/data/datasources/remote/session_remote_datasource.dart` (mới) | **OWN** | — | — |
| `mobile/lib/data/datasources/remote/transfer_remote_datasource.dart` | — | **OWN** | — |
| `mobile/lib/data/datasources/remote/transaction_remote_datasource.dart` | — | **OWN** | — |
| `mobile/lib/data/datasources/remote/wallet_transaction_remote_datasource.dart` | — | **OWN** | — |
| `mobile/lib/presentation/screens/auth/{otp_verification,set_pin,forgot_pin,forgot_password,reset_password,register}_screen.dart` | **OWN** | — | — |
| `mobile/lib/presentation/screens/settings/{device_management,notification_settings,change_pin}_screen.dart` | **OWN** | — | — |
| `mobile/lib/presentation/screens/more/more_screen.dart`, `widgets/side_menu_drawer.dart` | **OWN** | — | — |
| `mobile/lib/presentation/screens/{deposit_withdraw,bills,qr,cards,transfer/beneficiaries}_*` | — | **OWN** | — |
| `mobile/lib/presentation/screens/transfer/{confirm_transfer,transfer_confirm}_screen.dart` | — | **OWN** | — |
| `mobile/lib/presentation/screens/history/transaction_detail_screen.dart` | — | **OWN** | — |
| `mobile/lib/presentation/routes/app_router.dart` | — | **OWN** | — |
| `mobile/pubspec.yaml` / `pubspec.lock` | — | **OWN (optional)** | — |
| `mobile/test/**` hiện có | — | — | **OWN** |
| `mobile/test/contract/identity_contract_test.dart` (mới) | **OWN** | — | — |
| `mobile/test/contract/money_movement_contract_test.dart` (mới) | — | **OWN** | — |
| `mobile/test/contract/backend_inventory_test.dart` (mới) | — | — | **OWN** |
| `mobile/README.md`, `mobile/docs/**` | — | — | **OWN** |
| `.agents_workspace/**` (trừ report của mình) | report | report | **OWN** audit cuối |

### 7.2. Phụ thuộc

- Con 2 và Con 3 **chạy song song được** (vùng file rời nhau).
- Con 3 **được phép import** `backend_capabilities.dart` + `feature_unavailable.dart` do Con 2 tạo. Hợp đồng API được chốt cứng ở mục 7.3 (W9) — Con 3 code theo đúng chữ ký, không sửa file.
- Con 4 bắt đầu ngay với docs/test scaffold; **nghiệm thu cuối phải chạy sau khi Con 2 + Con 3 merge** (ghi rõ trạng thái "chờ merge" nếu chưa).
- Thứ tự merge đề xuất: **Con 2 → Con 3 → Con 4**. Không merge Con 4 trước vì test sẽ đỏ.

---

### 7.3. TASK_CON2 — Chuẩn hóa Identity / Onboarding / Profile / Session / Notification Settings

**Mục tiêu:** Mọi call thuộc identity–user–session–notification-settings khớp đúng backend thật; không còn "thành công giả"; người dùng mới đăng ký xong vào được Home.

**Đầu ra:** code + `mobile/test/contract/identity_contract_test.dart` + `.agents_workspace/02_CON2_REPORT.md`.

#### W1. Sửa refresh token (MOB-001) — P0
File: `mobile/lib/core/network/auth_interceptor.dart`
```dart
final response = await refreshDio.post(
  ApiConstants.refresh,
  data: {
    'refreshToken': refreshToken,
    if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
  },
);
```
- Parse: `data['accessToken'] ?? data['token']`, `data['refreshToken']`.
- Không gửi `queryParameters`.
- Nếu response không phải Map hoặc thiếu token ⇒ `complete(null)` + clear session (không crash).
- Thêm log an toàn (không log token).

#### W2. Logout thật (MOB-009) — P1
Files: `auth_remote_datasource.dart`, `more_screen.dart`, `side_menu_drawer.dart`
- Thêm `Future<void> logout()`: `POST /auth/logout` (Authorization Bearer) với `queryParameters: {'deviceId': deviceId}` nếu có.
- Gọi `PushNotificationService().unregisterDeviceFromBackend()` (best-effort).
- Sau đó mới xóa `accessToken`, `refreshToken`, `pinToken`, `walletId`; điều hướng `/auth/login`.
- Nếu API lỗi mạng: vẫn xóa local + điều hướng, nhưng ghi log; không chặn người dùng.

#### W3. Profile đúng hợp đồng (MOB-004) — P1
File: `profile_remote_datasource.dart`
- `updateMe`: `PUT ApiConstants.userProfile` với body `{'fullName': ..., 'email': ..., 'dateOfBirth': dob}`.
  - Thêm hằng `userProfile = '/users/profile'`; giữ `userMe` cho GET.
  - `dob` rỗng ⇒ bỏ field (không gửi chuỗi rỗng).
- `updateAvatar`: BE **không có** `/users/me/avatar`. Nếu `avatarUrl` là URL http(s) ⇒ `PUT /users/profile {'avatarUrl': url}`. Nếu là base64 (mobile đang gửi base64) ⇒ **không gọi API**, trả lỗi nghiệp vụ "Backend chưa hỗ trợ upload ảnh" và giữ ảnh local; UI hiển thị đúng.
- Xóa fallback `catch` gửi lại bằng query (che lỗi).

#### W4. KYC & limits (MOB-005) — P1
Files: `api_constants.dart`, `profile_remote_datasource.dart`, `kyc_level_screen.dart`
- Constants: `kycSubmit = '/kyc/submit'`, `kycStatus = '/kyc/status'`.
- `submitKyc` payload map đúng `KycSubmitRequest` (`documentType`, `documentNumber`, `frontImageUrl`, `backImageUrl?`, `faceImageUrl`, `issuedDate?`, `issuedPlace?`).
- `/config/limits` & `/config/limits/status` không tồn tại ⇒ bỏ call; dùng `dailyLimit`, `reservedBalance` từ `GET /wallets/me` (đã có trong `walletData`). Màn `kyc_level_screen` hiển thị dữ liệu ví + trạng thái KYC; nếu thiếu thì empty state, không bịa hạn mức.
- Nếu màn KYC upload chưa có backend lưu ảnh ⇒ gate ở nút submit bằng `FeatureUnavailable`.

#### W5. Money requests (MOB-006) — P1
Files: `api_constants.dart`, `money_request_remote_datasource.dart`
- Base: `/payments/money-requests`.
- Create body: `{requesterId, targetUserId, amount, note?, expiresInHours?}` (lấy `requesterId` từ secure storage `keyUserId`; `targetUserId` từ tham số).
- List: chỉ có `GET /payments/money-requests/user/{userId}` ⇒ `getReceived()` dùng userId hiện tại; `getSent()` **không có API** ⇒ trả `[]` + cờ "không hỗ trợ" (không gọi endpoint 404).
- Accept/Reject: thêm `queryParameters: {'payerUserId': currentUserId}`.
- Detail/Cancel: không có ⇒ loại khỏi datasource hoặc ném `UnsupportedError` có thông điệp; UI không gọi.
- Không đổi tên method public nếu screen đang dùng; giữ chữ ký tương thích.

#### W6. Sessions thật (MOB-008) — P1
Files: tạo `session_remote_datasource.dart`; sửa `device_management_screen.dart`
- `GET /sessions` → `data` là `List<SessionResponse>`.
- `DELETE /sessions/{sessionId}`.
- Bỏ toàn bộ hardcode Samsung/iPhone/iPad + lịch sử đăng nhập giả.
- Trạng thái: loading / empty ("Chưa có phiên nào") / error + Retry.
- Nút "Đăng xuất tất cả thiết bị khác": gọi tuần tự DELETE các session không phải hiện tại (hoặc chỉ session có `isCurrent=false` nếu BE trả).
- Không hiển thị "đã thu hồi" nếu API thất bại.

#### W7. Notification settings sync (MOB-010) — P1
File: `notification_settings_screen.dart`
- Khi lưu: `PUT /notifications/settings?transactionEnabled={_balanceChangeNotif}&promoEnabled={_promoRewardNotif}`.
- Load: BE **không có GET settings** ⇒ giữ local cho hiển thị; sau khi PUT thành công mới báo "Đã đồng bộ với máy chủ".
- Các cờ không được BE hỗ trợ (SMS, email, âm thanh, DND, ngưỡng) ghi chú "chỉ áp dụng trên thiết bị này".
- Lỗi API ⇒ báo lỗi, không báo thành công.

#### W8. Onboarding không ngõ cụt (MOB-003) — P0
Files: `register_screen.dart`, `otp_verification_screen.dart`, `set_pin_screen.dart`, `forgot_pin_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`
- Register: BE trả token ngay ⇒ lưu token (đã có trong datasource) và `context.go('/')`; **bỏ bước OTP/PIN bắt buộc**.
- OTP screen: nếu vẫn vào được, hiển thị "Backend chưa hỗ trợ OTP" + nút quay lại; **không** hiển thị thành công.
- Set PIN / Forgot PIN / Change PIN: disable nút xác nhận, hiển thị lý do; không gọi `/users/pin/*`.
- Forgot/Reset password: hiển thị hướng dẫn liên hệ CSKH; không gọi endpoint 404.
- Không xóa màn hình; giữ route để tương thích deep link.

#### W9. Hạ tầng gate dùng chung (bắt buộc, để Con 3 import)
Tạo `mobile/lib/core/constants/backend_capabilities.dart`:
```dart
/// Nguồn: audit AUDIT-MOB-BE-001, commit 75bf273.
/// Bật lại khi backend bổ sung endpoint tương ứng (xem BE-REQ trong 01_ISSUES_AND_TASKS.md).
class BackendCapabilities {
  BackendCapabilities._();

  static const bool serverSideTransferAuth = false; // BE-REQ-03
  static const bool otp = false;                    // BE-REQ-04
  static const bool transactionPin = false;         // BE-REQ-03
  static const bool deposit = false;                // BE-REQ-06
  static const bool withdraw = false;               // BE-REQ-06
  static const bool bills = false;                  // BE-REQ-06
  static const bool vietQr = false;                 // BE-REQ-06
  static const bool bankAccounts = false;           // BE-REQ-06
  static const bool fundingSources = false;         // BE-REQ-06
  static const bool beneficiaries = false;          // BE-REQ-06
  static const bool receiptAndExport = false;       // BE-REQ-06
  static const bool referrals = false;              // BE-REQ-06
  static const bool legalDocuments = false;         // BE-REQ-06
  static const bool feedback = false;               // BE-REQ-06
  static const bool moneyRequestDetail = false;     // BE-REQ-06
  static const bool moneyRequestCancel = false;     // BE-REQ-06
}
```
Tạo `mobile/lib/presentation/widgets/feature_unavailable.dart`:
```dart
Future<void> showFeatureUnavailable(
  BuildContext context, {
  required String feature,
  required String reason,
});
```
- Dialog chuẩn: tiêu đề "Tính năng chưa sẵn sàng", nội dung `reason`, nút "Đã hiểu".
- Dùng chung cho Con 3; **không** tự tạo bản sao.

#### W10. Test hợp đồng identity (bắt buộc)
File mới: `mobile/test/contract/identity_contract_test.dart`
- MockDio; assert:
  - refresh gửi `data` là Map, không có query `refreshToken`.
  - `PUT /users/profile` body có `dateOfBirth`, không có query.
  - KYC dùng `/kyc/submit`, `/kyc/status`.
  - money request create dùng `/payments/money-requests` + `requesterId`/`targetUserId`.
  - sessions dùng `/sessions`.
- Không sửa test của Con 4.

#### DoD của TASK_CON2
- [ ] `flutter analyze` sạch.
- [ ] `flutter test test/contract/identity_contract_test.dart` pass.
- [ ] Không còn call nào tới `/auth/otp/*`, `/users/pin/*`, `/users/kyc*`, `/config/limits*`, `/users/me/avatar` trong code production (trừ khi nằm sau gate và có comment `BE-GAP`).
- [ ] Register → Home chạy được (widget test hoặc manual).
- [ ] Backend guard rỗng + checksum khớp.
- [ ] Báo cáo `02_CON2_REPORT.md` liệt kê file đã sửa + bằng chứng.

#### Ngoài phạm vi TASK_CON2
- Không sửa transfer/history/dio_client.
- Không sửa test hiện có của Con 4.
- Không thêm endpoint giả; không sửa backend.

---

### 7.4. TASK_CON3 — Chuẩn hóa Money Movement, History & Tối ưu tầng mạng

**Mục tiêu:** Chặn rủi ro mất tiền do xác thực giả; giảm RTT; sửa sai lệch chi tiết giao dịch; tắt rò rỉ log; gate các màn không có backend.

**Đầu ra:** code + `mobile/test/contract/money_movement_contract_test.dart` + `.agents_workspace/03_CON3_REPORT.md`.

#### W1. Tầng mạng dùng chung & an toàn log (MOB-011/016/021) — P1
File: `dio_client.dart`
- Thêm `static final DioClient instance` / `static Dio get sharedDio` (singleton).
- `PrettyDioLogger`: chỉ thêm khi `!kReleaseMode`; `requestHeader: false`; không log body chứa token/PIN.
- Thêm `sendTimeout: 15s`.
- **Không** thêm retry tự động cho POST (tránh double debit). Nếu thêm retry, chỉ cho GET idempotent.
- Cập nhật các datasource trong vùng sở hữu dùng `DioClient.sharedDio`. **Không sửa** datasource của Con 2; ghi đề xuất trong report.

#### W2. Chặn giao dịch khi chưa có xác thực server-side (MOB-002) — P0
Files: `confirm_transfer_screen.dart`, `transfer_confirm_screen.dart`, `transfer_remote_datasource.dart`
- Import `BackendCapabilities` + `showFeatureUnavailable`.
- Trong `_submitTransfer`, **trước** `initTransfer`:
  ```dart
  if (!BackendCapabilities.serverSideTransferAuth) {
    await showFeatureUnavailable(context,
      feature: 'Xác thực chuyển tiền',
      reason: 'Backend chưa cung cấp API xác thực PIN/OTP (BE-REQ-03). '
              'Giao dịch được tạm khóa để tránh rủi ro mất tiền.');
    return;
  }
  ```
- Xóa nhánh giả lập: `confirmTransfer` không được trả "thành công" từ map local. Nếu cờ bật (tương lai), gọi endpoint thật; nếu chưa có endpoint, ném `UnsupportedError`.
- Xóa/đổi tên comment "PIN/OTP đã được xác thực".
- Không hiển thị bất kỳ text nào ngụ ý PIN đã được BE kiểm tra.

#### W3. Giảm RTT chuyển tiền (MOB-014 / OPT-01) — P2
File: `transfer_remote_datasource.dart` + 2 screen gọi
- Đổi `initTransfer` nhận thêm `required String sourceUserId, required String targetUserId` (hoặc `Recipient` object).
- Screen lấy:
  - `sourceUserId` từ `AuthLocalDataSource` (`AppConstants.keyUserId`).
  - `targetUserId` từ `getRecipient()` (response đã có `ownerId`).
- Chỉ fallback `_ownerIdOfWallet` khi ownerId rỗng; log warning.
- Kỳ vọng: bỏ 2 GET; còn 1 POST (+ recipient-info nếu chưa có).
- **Không** đổi hợp đồng BE; vẫn gửi `sourceUserId`/`targetUserId` như cũ (dù BE có lỗi IDOR — ghi nhận).

#### W4. Idempotency & vòng đời confirm (MOB-017) — P2
- Sinh `idempotencyKey` **một lần** khi người dùng bắt đầu xác nhận; truyền vào `initTransfer`; retry mạng dùng lại đúng key.
- `_completedTransfers`: giới hạn tối đa 5 entry, xóa sau khi đọc; không giữ vô hạn.
- Nếu app khởi động lại giữa init và confirm: không giả vờ thành công; hiển thị "Kiểm tra lịch sử giao dịch" và điều hướng history.
- Key format giữ nguyên prefix `MOBILE-` để BE không phải đổi.

#### W5. Chi tiết giao dịch đúng góc nhìn (MOB-015) — P2
Files: `transaction_remote_datasource.dart`, `transaction_detail_screen.dart`
- `getTransaction(String id, {String? walletId})`; gọi `GET /transactions/{id}?walletId=...`.
- Screen đọc `walletId` từ secure storage (`keyWalletId`).
- Test: giao dịch `TRANSFER_IN` phải hiển thị `amount > 0`, `runningBalance` đúng.

#### W6. Hợp nhất 2 màn xác nhận chuyển tiền (MOB-019) — P2
- Chọn **một** luồng chuẩn: `ConfirmTransferScreen` (numpad) hoặc `TransferConfirmScreen` (OTP text) — đề xuất giữ `ConfirmTransferScreen`, vì có numpad + xử lý lỗi tốt hơn.
- Route còn lại redirect sang luồng chuẩn hoặc xóa import/route; cập nhật `app_router.dart`.
- Không để hai màn cùng gọi `initTransfer` với hành vi khác nhau.

#### W7. Gate các màn không có backend (MOB-007) — P1
Dùng `showFeatureUnavailable` (do Con 2 tạo) tại **hành động gửi tiền/tiêu tiền**, không cần xóa UI:
- `deposit_withdraw/deposit_screen.dart`, `deposit_confirm_screen.dart`
- `deposit_withdraw/withdraw_screen.dart`, `withdraw_confirm_screen.dart`
- `bills/*` (bill payment, topup, phone recharge, savings, quick loan, lottery) — chặn ở nút xác nhận/thanh toán
- `qr/scan_qr_screen.dart`, `qr/my_qr_screen.dart` — chặn decode/generate
- `cards/bank_cards_screen.dart`, `cards/payment_methods_screen.dart` — chặn link/unlink
- `transfer/beneficiaries_screen.dart` — chặn thêm/sửa beneficiary
- Lý do hiển thị đúng BE-REQ tương ứng; **không** hiển thị SnackBar thành công giả.
- Nếu một phần dữ liệu đọc được từ BE (ví dụ wallet, profile) thì vẫn hiển thị; chỉ chặn mutation.

#### W8. Tối ưu ảnh (MOB-020) — P3 optional
- Chỉ thêm `cached_network_image` nếu Lead/user duyệt; nếu không, dùng `Image.network(..., cacheWidth: ...)` và ghi chú.
- Không sửa `pubspec.lock` thủ công; chạy `flutter pub get` và kiểm tra diff.

#### W9. Test hợp đồng money movement (bắt buộc)
File mới: `mobile/test/contract/money_movement_contract_test.dart`
- Assert `initTransfer` chỉ gọi `POST /payments/transfer`, không gọi `GET /wallets/{id}` khi đã truyền ownerId.
- Assert `getTransaction` gửi `walletId`.
- Assert khi `serverSideTransferAuth=false` không có request POST nào được gửi.
- Assert logger không chứa body ở release? (có thể test cấu hình).

#### DoD của TASK_CON3
- [ ] Không còn khả năng chuyển tiền khi cờ `serverSideTransferAuth=false`.
- [ ] Số HTTP call của luồng chuyển tiền giảm từ 3 → 1 (đo bằng MockDio, ghi log).
- [ ] `getTransaction` có `walletId`; test TRANSFER_IN đúng dấu.
- [ ] `flutter analyze` sạch; test contract pass.
- [ ] Không sửa file của Con 2/Con 4.
- [ ] Backend guard rỗng.
- [ ] Báo cáo `03_CON3_REPORT.md` kèm số call trước/sau.

#### Ngoài phạm vi TASK_CON3
- Không sửa auth/profile/session/notification settings.
- Không sửa backend dù phát hiện IDOR.
- Không refactor toàn bộ kiến trúc BLoC.

---

### 7.5. TASK_CON4 — Kiểm chứng, Test & Đính chính báo cáo

**Mục tiêu:** Biến bộ test thành công cụ chặn drift; đính chính mọi tuyên bố sai; tạo bằng chứng tái lập; không sửa code sản phẩm.

**Đầu ra:** test + docs + `.agents_workspace/04_CON4_REPORT.md` + `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md`.

#### W1. Triage test suite (MOB-013) — P1
- `be_integration_test.dart`: thêm `@Tags(['e2e'])`; đọc biến `RUN_E2E` (`String.fromEnvironment`); nếu không bật ⇒ `skip: 'E2E cần backend :8080'` cho toàn bộ group. Không xóa test.
- Thêm `mobile/dart_test.yaml` khai báo tag `e2e` (nếu cần) và timeout hợp lý.
- Mục tiêu: `flutter test` mặc định **không còn 36 fail do môi trường**.
- Cập nhật `remote_datasources_test.dart` theo code mới của Con 3 (chỉ sau khi Con 3 merge): bỏ kỳ vọng `/wallets/transfer/init` + `/confirm`; thay bằng `/payments/transfer`.
- Không được hạ assertion để "cho xanh"; mỗi thay đổi phải dẫn chiếu BE `file:line`.

#### W2. Contract test chống drift (MOB-024) — P1
File mới: `mobile/test/contract/backend_inventory_test.dart`
- Đọc (read-only) `../backend/services/**/Controller.java`, trích `@RequestMapping` + method mapping.
- Đối chiếu danh sách path mobile thực sự gọi (khai báo tường minh trong test, không reflect).
- Assert:
  - Mọi path đang dùng **có** trong inventory BE.
  - Các path thuộc BE-GAP nằm trong danh sách `knownBackendGaps` có comment + link BE-REQ tương ứng.
- Test này **không sửa backend**, chỉ đọc file.

#### W3. Đính chính README (MOB-012) — P1
File: `mobile/README.md`
- Badge test: đổi thành số thật (sau khi W1 xanh) hoặc bỏ badge.
- Bỏ/sửa: `GlassQuality.premium` cho Balance/Cards; `contentAwareBrightness` tự động; "Clean Architecture" nếu chưa có repo/usecase/BLoC; "xác nhận an toàn PIN/OTP"; FPS 60/120 (ghi "chưa đo").
- Ghi rõ giới hạn: "UI presentation gọi datasource trực tiếp; chưa có BLoC/repository".
- Thêm mục "Backend gaps" link tới tài liệu audit.

#### W4. Đính chính báo cáo FE–BE & API guide — P1
Files: `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md`, `mobile/docs/API_INTEGRATION_GUIDE.md`, `mobile/docs/BAO_CAO_KIEM_TRA_LUONG_NUT_BAM.md`
- Thêm header **"SUPERSEDED — nội dung dưới đây là đặc tả lịch sử, không phản ánh backend commit 75bf273"**.
- Thêm Phụ lục "Hợp đồng thực tế" (bảng đúng/sai theo mục 3).
- Chuyển các endpoint không tồn tại sang "BE backlog" (BE-REQ-04/06).
- Sửa báo cáo nút bấm: "51 route tồn tại, nhưng X màn chưa có backend; Y màn mô phỏng" — đếm chính xác từ Phụ lục A.

#### W5. Báo cáo audit cuối & bằng chứng — P1
File: `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md`
- Verdict trước/sau; bảng claim → trạng thái; danh sách issue đã đóng/chưa đóng.
- Log `flutter analyze`, `flutter test`, `flutter test --tags e2e` (nếu chạy được), backend guard.
- Tuyệt đối không ghi "đã tối ưu X%" nếu không có phép đo.

#### W6. Quy trình chặn hồi quy
- Thêm mục "Definition of Done" vào README mobile: mọi PR phải chạy analyze + test + contract test + backend guard.
- Đề xuất CI (không bắt buộc): job `flutter analyze`, `flutter test`, `contract test`.

#### DoD của TASK_CON4
- [ ] `flutter test` mặc định: **0 fail** (e2e skip có lý do rõ).
- [ ] `flutter test --tags e2e` chỉ chạy khi `RUN_E2E=true` và backend sẵn sàng (ghi rõ trong README).
- [ ] Contract test đọc backend pass; danh sách BE-GAP được kiểm soát.
- [ ] Không còn tuyên bố sai trong README/docs mobile (grep các từ khóa: `6/6`, `premium`, `60/120`, `PIN/OTP`, `Clean Architecture`).
- [ ] `05_MOBILE_BE_AUDIT_FINAL.md` có verdict + bằng chứng.
- [ ] Backend guard rỗng + checksum khớp.

#### Ngoài phạm vi TASK_CON4
- Không sửa `mobile/lib/**` (trừ khi được Lead cho phép đặc biệt).
- Không sửa backend.
- Không "làm đẹp" số liệu.

---

## 8. GATE & TIÊU CHÍ NGHIỆM THU TỔNG

| Gate | Điều kiện | Ai chịu trách nhiệm |
|---|---|---|
| **G0 — Baseline** | analyze sạch, test baseline ghi nhận, backend hash khớp | Con 1 (đã xong) |
| **G1 — Identity** | MOB-001/003/004/005/006/008/009/010 đóng; contract test identity pass | Con 2 |
| **G2 — Money** | MOB-002/011/014/015/016/017/019 đóng; số RTT giảm; test contract money pass | Con 3 |
| **G3 — Verification** | test mặc định xanh; e2e opt-in; docs đính chính; audit cuối | Con 4 |
| **G4 — Sign-off** | backend diff rỗng + checksum khớp; không còn unguarded call tới endpoint không tồn tại; verdict cập nhật | Con 1 + user |

### 8.1. Lệnh nghiệm thu

```bash
# 1. Backend bất biến
git status --porcelain -- backend          # rỗng
git diff --name-only -- backend            # rỗng
git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
# eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003

# 2. Mobile
cd mobile
flutter analyze
flutter test                                # phải 0 fail sau TASK_CON4
flutter test test/contract                 # contract tests

# 3. Không còn call chưa gate tới endpoint không tồn tại
grep -rn "users/pin\|auth/otp\|wallets/deposit\|wallets/withdraw\|bills/\|vietqr\|bank-accounts\|funding-sources\|beneficiaries\|config/limits\|users/kyc\|receipt.pdf\|export/" lib
# Mọi kết quả phải nằm sau BackendCapabilities hoặc có comment BE-GAP

# 4. E2E (chỉ khi stack chạy)
RUN_E2E=true flutter test --tags e2e
```

### 8.2. Tiêu chí "chuẩn với BE" (định nghĩa dứt khoát)

Một call mobile được coi là "chuẩn" khi:
1. Path + method tồn tại trong controller BE tại commit nền.
2. Query/body/header khớp DTO/annotation BE.
3. Response được parse theo đúng envelope của service đó.
4. Có xử lý lỗi và không hiển thị thành công giả.
5. Có test hoặc contract test chứng minh.

---

## 9. RỦI RO & CÁCH XỬ LÝ

| Rủi ro | Mức | Xử lý |
|---|---|---|
| Không thể xác thực PIN/OTP do BE thiếu API | P0 | Chặn giao dịch (MOB-002), escalate BE-REQ-03; không giả lập |
| Chặn chuyển tiền ảnh hưởng demo/nghiệm thu | Cao | Cờ `serverSideTransferAuth` có thể bật khi BE sẵn sàng; thông báo rõ cho stakeholder |
| Sửa nhiều màn gây regression UI | Trung | Gate ở action, giữ nguyên layout; test widget; merge từng task |
| Test e2e che lỗi thật | Trung | Không xóa; tách tag + tài liệu hóa; chạy định kỳ với stack |
| Hai Con sửa cùng file | Cao | Ma trận sở hữu 7.1; chỉ Con 2 tạo file dùng chung; Con 3 import |
| `pubspec.lock` đang dirty | Thấp | Không revert; chỉ Con 3 chạm nếu thêm dependency |
| Backend bị sửa nhầm | Nghiêm trọng | Guard trước/sau; dừng ngay nếu checksum lệch |

---

## 10. PHỤ LỤC A — BẢN ĐỒ ENDPOINT MOBILE ↔ BACKEND

Ký hiệu: ✅ có; ❌ không tồn tại; ⚠️ có nhưng sai method/path/payload.

| Mobile (`api_constants.dart`) | Dòng | BE thực tế | Trạng thái |
|---|---:|---|---|
| `/auth/login` | 16 | `AuthController:30` | ✅ |
| `/auth/refresh` | 17 | `AuthController:41` | ⚠️ query vs body |
| `/auth/register` | 18 | `AuthController:22` | ✅ (deviceId dư, Jackson bỏ qua) |
| `/auth/otp/verify` | 19 | — | ❌ |
| `/auth/otp/send` | 20 | — | ❌ |
| `/auth/forgot-password` | 21 | — | ❌ |
| `/auth/reset-password` | 22 | — | ❌ |
| `/auth/logout` | 23 | `AuthController:47` | ✅ nhưng mobile không gọi |
| `/users/pin/set` | 24 | — | ❌ |
| `/users/pin/verify` | 25 | — | ❌ |
| `/security/biometric/verify` | 26 | — | ❌ (local_auth only) |
| `/wallets/me` | 29 | `WalletRestController:43` | ✅ |
| `/wallets/{id}` | 30 | `:56` | ✅ (thiếu ownership check) |
| `/wallets/recipient-info` | 31 | `:68` | ✅ |
| `/wallets/fees/estimate` | 32 | `:110` | ✅ |
| `/payments/transfer` | 33 | `TransferController:22` | ✅ (IDOR) |
| `/wallets/transfer/init` | 34 | — | ❌ (test cũ vẫn kỳ vọng) |
| `/wallets/transfer/{id}/confirm` | 35 | — | ❌ |
| `/wallets/deposit` | 36 | — | ❌ |
| `/wallets/withdraw` | 37 | — | ❌ |
| `/transactions` | 40 | `TransactionHistoryController:39` | ✅ |
| `/transactions/{id}` | 41 | `:68` | ✅ (thiếu `walletId` phía mobile) |
| `/transactions/{id}/receipt.pdf` | 42 | — | ❌ |
| `/transactions/export/{format}` | 43 | — | ❌ |
| `/payments/vietqr/decode` | 46 | — | ❌ |
| `/payments/vietqr/generate` | 47 | — | ❌ |
| `/users/me/qrcode` | 48 | — | ❌ |
| `/bills/lookup` | 51 | — | ❌ |
| `/bills/pay` | 52 | — | ❌ |
| `/bills/topup` | 53 | — | ❌ |
| `/banks` | 56 | `/payments/banks` (`BankController:13`) | ⚠️ |
| `/beneficiaries` | 57 | — | ❌ |
| `/funding-sources` | 58 | — | ❌ |
| `/bank-accounts` | 59 | — | ❌ |
| `/users/me` | 62 | `UserController:24` | ✅ (GET) |
| `/users/me/avatar` | 63 | — | ❌ |
| `/users/kyc` | 64 | `/kyc/submit` (`KycController:25`) | ⚠️ |
| `/users/kyc/status` | 65 | `/kyc/status` (`:35`) | ⚠️ |
| `/config/limits/status` | 66 | — | ❌ |
| `/sessions` | 69 | `SessionController:24` | ✅ |
| `/sessions/{id}` | 70 | `:33` | ✅ |
| `/sessions/{id}/fcm` | 71 | — | ❌ |
| `/notifications` | 72 | `NotificationController:29` | ✅ |
| `/notifications/{id}/read` | 73 | `:48` | ✅ |
| `/notifications/read-all` | 74 | `:57` | ✅ |
| `/support/faq` | 75 | `SupportController:70` | ✅ |
| `/support/tickets` | 76 | `:31` | ✅ |
| `/bank-accounts/link` | 79 | — | ❌ |
| `/bank-accounts/{id}` | 80 | — | ❌ |
| `/config/limits` | 83 | — | ❌ |
| `/legal/terms` | 84 | — | ❌ |
| `/legal/consent` | 85 | — | ❌ |
| `/money-requests` | 88 | `/payments/money-requests` | ⚠️ |
| `/money-requests/received` | 89 | — | ❌ |
| `/money-requests/sent` | 90 | — | ❌ |
| `/money-requests/{id}` | 91 | — | ❌ |
| `/money-requests/{id}/accept` | 92 | `:55` + `?payerUserId` | ⚠️ |
| `/money-requests/{id}/reject` | 93 | `:69` + `?payerUserId` | ⚠️ |
| `/money-requests/{id}/cancel` | 94 | — | ❌ |
| `/promotions` | 97 | `PromotionController:28` | ✅ |
| `/promotions/my-vouchers` | 98 | `:59` | ✅ |
| `/promotions/redeem` | 99 | `:40` | ✅ |
| `/promotions/apply` | 100 | `:49` | ✅ |
| `/referrals/code` | 101 | — | ❌ |
| `/referrals/history` | 102 | — | ❌ |
| `/referrals/apply` | 103 | — | ❌ |
| `/feedback` | 104 | — | ❌ |
| `/devices/register` | 107 | `DeviceController:27` | ✅ |
| `/devices/unregister` | 108 | `:37` | ✅ |

**Tổng hợp:** **24 ✅ / 7 ⚠️ / 38 ❌** trên 69 bề mặt API được khai báo (một số hằng không dùng trực tiếp nhưng vẫn nằm trong datasource).

---

## 11. PHỤ LỤC B — BẰNG CHỨNG CHÍNH (file:line)

### Backend
- `backend/services/identity-service/src/main/java/com/fintech/identity/controller/AuthController.java:22,30,41,47`
- `backend/services/identity-service/src/main/java/com/fintech/identity/dto/RefreshTokenRequest.java:15-21`
- `backend/services/identity-service/src/main/java/com/fintech/identity/controller/UserController.java:24,32`
- `backend/services/identity-service/src/main/java/com/fintech/identity/controller/KycController.java:25,35`
- `backend/services/identity-service/src/main/java/com/fintech/identity/controller/SessionController.java:24,33`
- `backend/services/payment-service/src/main/java/com/fintech/payment/controller/TransferController.java:13,22,31`
- `backend/services/payment-service/src/main/java/com/fintech/payment/controller/TransactionHistoryController.java:30,39,68`
- `backend/services/payment-service/src/main/java/com/fintech/payment/controller/MoneyRequestController.java:18,27,55,69,83`
- `backend/services/payment-service/src/main/java/com/fintech/payment/dto/ApiResponse.java` (không `errorCode/timestamp`)
- `backend/services/wallet-service/src/main/java/com/fintech/wallet/infrastructure/web/WalletRestController.java:29,43,56,68,110`
- `backend/services/notification-service/src/main/java/com/fintech/notification/controller/NotificationController.java:29,66`
- `backend/services/api-gateway/src/main/resources/application.yml:262-263`
- `backend/services/api-gateway/src/main/java/com/fintech/gateway/JwtAuthenticationFilter.java:59-65,186`
- `backend/services/payment-service/src/main/java/com/fintech/payment/saga/PaymentSagaOrchestrator.java:69-79`

### Mobile
- `mobile/lib/core/constants/api_constants.dart:15-109`
- `mobile/lib/core/network/auth_interceptor.dart:57-70,123-152`
- `mobile/lib/core/network/dio_client.dart:14-31`
- `mobile/lib/core/network/idempotency_interceptor.dart:7-21`
- `mobile/lib/data/datasources/remote/transfer_remote_datasource.dart:10,64-93,96-118`
- `mobile/lib/data/datasources/remote/transaction_remote_datasource.dart:69-73`
- `mobile/lib/data/datasources/remote/profile_remote_datasource.dart:65-110`
- `mobile/lib/data/datasources/remote/money_request_remote_datasource.dart:13-23,39-50`
- `mobile/lib/presentation/screens/transfer/confirm_transfer_screen.dart:108-131`
- `mobile/lib/presentation/screens/transfer/transfer_confirm_screen.dart:84-91`
- `mobile/lib/presentation/screens/settings/device_management_screen.dart:25-120`
- `mobile/lib/presentation/screens/settings/notification_settings_screen.dart:53-100`
- `mobile/lib/presentation/screens/more/more_screen.dart:189-200`
- `mobile/lib/presentation/widgets/side_menu_drawer.dart:240-249`
- `mobile/lib/presentation/screens/history/transaction_detail_screen.dart:80`
- `mobile/lib/presentation/screens/history/transaction_history_screen.dart:449`
- `mobile/lib/presentation/screens/shell/main_tabs_screen.dart:28`
- `mobile/lib/presentation/routes/app_router.dart:166,323,340`
- `mobile/lib/main.dart:13-16`
- `mobile/README.md:7,9,18-20,24,28-29`
- `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md:27-29,51-80,142-210,264-395`
- `mobile/docs/API_INTEGRATION_GUIDE.md:220,298,457,524,561,639`
- `mobile/test/remote_datasources_test.dart:259,284`
- `mobile/test/be_integration_test.dart` (Group 1–11)

---

## 12. PHỤ LỤC C — BACKEND GUARD (bắt buộc)

```bash
cd /home/buidi/core-banking-microservices

echo "== status =="
git status --porcelain -- backend

echo "== diff =="
git diff --name-only -- backend

echo "== checksum =="
git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
# Baseline: eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003
```

Nếu bất kỳ lệnh nào khác baseline:
1. Dừng công việc.
2. Ghi lại output.
3. Báo Lead ngay — **không tự revert**, không tiếp tục sửa.

---

## 13. KẾT LUẬN

- Báo cáo hiện tại **không đạt** tiêu chí "chuẩn với backend": **17 tuyên bố sai hoàn toàn** + nhiều tuyên bố chỉ đúng một phần, **38 bề mặt API không tồn tại**, **7 bề mặt sai hợp đồng**, **2 lỗi P0 mobile** và **1 lỗ hổng P0 backend (IDOR)**.
- Ba task được thiết kế **độc lập về vùng file**, có hợp đồng dùng chung rõ ràng, không chồng lấn, và **không chạm backend**.
- Ưu tiên tuyệt đối: **MOB-001 (refresh)**, **MOB-002 (PIN/OTP giả)**, **MOB-003 (onboarding)**, **BE-REQ-01/02 (IDOR)**.
- Mọi tuyên bố hiệu năng phải được đo lại bằng profile mode trên thiết bị thật; các tối ưu trong tài liệu này chỉ là **cơ hội có căn cứ code**, không phải số đo.

> **Nhắc lại lần cuối:** Không sửa backend. Mọi vấn đề thuộc BE chỉ được ghi thành `BE-REQ-*` và chuyển cho Backend team.
