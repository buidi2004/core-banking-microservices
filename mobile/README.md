# 📱 Sen Hồng Bank (Fintech E-Wallet Flutter Client)

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2.svg)](https://dart.dev/)
[![Architecture](https://img.shields.io/badge/Architecture-UI%20calls%20DataSource%20directly-orange.svg)](#-ki%E1%BA%BFn-tr%C3%BAc-th%E1%BB%B1c-t%E1%BA%BF)
[![Liquid Glass UI](https://img.shields.io/badge/UI-Liquid%20Glass%20Widgets-9cf.svg)](#-%C4%91i%E1%BB%83m-n%E1%BB%95i-b%E1%BA%ADt-v%E1%BB%81-ui)
[![Tests](https://img.shields.io/badge/Unit%20Tests-49%2F87%20Passed-yellow.svg)](#-ki%E1%BB%83m-th%E1%BB%AD-t%E1%BB%B1-%C4%91%E1%BB%99ng)

> ⚠️ **TRẠNG THÁI HIỆN TẠI (Audit 2026-10-20):** Báo cáo này đã được đính chính dựa trên audit `AUDIT-MOB-BE-001`. Nhiều tuyên bố trong phiên bản cũ **KHÔNG ĐÚNG** so với backend thực tế tại commit `75bf273`. Xem [Báo cáo Audit Cuối](./.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md) để biết chi tiết.

Ứng dụng ví điện tử tài chính số **Sen Hồng Bank** được xây dựng trên nền tảng **Flutter 3** với bộ widget hiệu ứng kính quang học **`liquid_glass_widgets`**.

---

## 🌟 Điểm Nổi Bật Về UI (Đã Xác Thực)

1. **Giao Diện Kính Quang Học Thời Thượng (Liquid Glass UI):**
   - Tính toán và render trực tiếp bằng **Flutter fragment shader (Impeller/Skia)** thông qua cây widget thuần, khắc phục triệt để lỗi chạm xuyên (touch-through) trên Android.
   - **Phân tầng chất lượng:**
     - **Thanh điều hướng (`MainTabsScreen`)**: Dùng `GlassScaffold` + `GlassTabBar.bottom` với `contentAwareBrightness: false` (cố định, KHÔNG tự động).
     - **Lịch sử giao dịch (`TransactionHistoryScreen`)**: Sử dụng `GlassQuality.minimal` tối ưu hóa GPU.
     - ⚠️ **Balance Card & Virtual Card**: KHÔNG dùng `GlassQuality.premium` (chỉ bottom bar dùng premium).

2. **Khả Năng Đồng Bộ & Kết Nối Backend Microservices:**
   - **Tự động Reverse Port ADB:** Script `mobile/run.sh` tự động cấu hình `adb reverse tcp:8080 tcp:8080`, cho phép thiết bị Android thật giao tiếp thẳng với Spring Cloud API Gateway qua `http://localhost:8080` mà không cần đổi IP mạng LAN.
   - **Chuyển tiền P2P:** Gọi endpoint `POST /payments/transfer` (single-step). ⚠️ **KHÔNG có xác thực PIN/OTP server-side** (backend chưa cung cấp API này - xem BE-REQ-03). Mobile hiện **chặn giao dịch** để bảo vệ tài khoản.
   - **Realtime WebSocket & Floating HUD Notification:** Kết nối Native STOMP WebSocket (`/ws-native`), tự động nhận diện và hiển thị thông báo biến động số dư dạng SMS Banking nổi trên toàn ứng dụng.

3. **Điều Hướng & Quản Lý Trạng Thái:**
   - **Stateful Shell Route (`go_router`)**: Duy trì trạng thái giao diện và vị trí cuộn khi chuyển đổi qua lại giữa 4 Tab chính.
   - **State Management:** Sử dụng `ValueNotifier`/`ChangeNotifier` pattern. `flutter_bloc` được khai báo trong `pubspec.yaml` nhưng **CHƯA được sử dụng** trong code production.

4. **Bảo Mật:**
   - Bàn phím số bảo mật xáo trộn ngẫu nhiên `CustomPinNumpad`.
   - Sinh trắc học Vân tay & Khuôn mặt FaceID (`local_auth`).
   - Lưu trữ an toàn Key / Token trong phần cứng `flutter_secure_storage` (Android Keystore / iOS Keychain).
   - ⚠️ **KHÔNG có xác thực PIN/OTP giao dịch phía server** - backend chưa cung cấp API.

---

## 📁 Cấu Trúc Dự Án (Thực Tế - KHÔNG phải Clean Architecture)

```text
mobile/
├── lib/
│   ├── core/
│   │   ├── constants/               # ApiConstants, AppConstants, BackendCapabilities
│   │   ├── network/                 # DioClient, AuthInterceptor, ErrorParser, IdempotencyInterceptor
│   │   ├── security/                # BiometricAuthService, SecureStorage
│   │   ├── theme/                   # AppColors, AppTypography, GlassThemeData
│   │   └── utils/                   # CurrencyFormatter, DateFormatter, VietQR
│   ├── data/
│   │   ├── datasources/             # Remote API (Dio) & Local Secure Storage
│   │   ├── models/                  # DTO Models (JSON Serializable)
│   │   └── repositories/            # THƯ MỤC TỒN TẠI NHƯNG CHƯA CÓ TRIỂN KHAI REPOSITORY
│   ├── domain/
│   │   ├── entities/                # User, Wallet, Transaction, Notification
│   │   └── repositories/            # TRỐNG - CHƯA CÓ INTERFACE
│   └── presentation/
│       ├── routes/                  # GoRouter configuration (4 Tabs & Flow routes)
│       ├── screens/                 # 51 màn hình chức năng (10 phân hệ nghiệp vụ)
│       │   ├── shell/               # MainTabsScreen (GlassScaffold + BottomBar)
│       │   ├── home/                # HomeScreen (BalanceCard - GlassQuality.standard)
│       │   ├── cards/               # CardsScreen (Thẻ Visa/Mastercard ảo - GlassQuality.minimal/standard)
│       │   ├── qr/                  # ScanQRScreen, MyQRScreen (VietQR - BE-GAP)
│       │   ├── promotions/          # PromotionsScreen (Voucher/Ưu đãi)
│       │   ├── more/                # MoreScreen (Cài đặt & Tiện ích mở rộng)
│       │   ├── auth/                # Login, Register, OTP (BE-GAP), SetPin (BE-GAP)
│       │   ├── transfer/            # ChooseRecipient, EnterAmount, ConfirmTransfer (chặn nếu BE thiếu auth)
│       │   ├── history/             # TransactionHistory, TransactionDetail
│       │   ├── bills/               # BillPayment, PhoneRecharge, Savings, QuickLoan, Lottery (BE-GAP)
│       │   └── settings/            # SecuritySettings, Biometrics, DeviceManagement, Notifications
│       └── widgets/                 # FloatingNotificationHUD, GlassCard, CustomKeypad, FeatureUnavailable
├── test/
│   ├── contract/                    # Contract tests (identity, money_movement, backend_inventory)
│   ├── be_integration_test.dart     # E2E tests (tagged 'e2e', skipped by default)
│   ├── remote_datasources_test.dart # Unit tests với MockDio (đã cập nhật hợp đồng BE thật)
│   └── ... (widget/screen tests)
├── bin/
│   └── test_be.dart                 # Script kiểm thử kết nối Backend Probe
└── run.sh                           # CLI điều khiển toàn diện ứng dụng Mobile
```

> **Lưu ý:** Kiến trúc hiện tại là **Presentation → DataSource trực tiếp** (không có Repository/Usecase/BLoC). Đây là nợ kỹ thuật (MOB-023), không phải Clean Architecture.

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy

### Cách 1: Sử Dụng CLI `mobile/run.sh` (Khuyên Dùng)

```bash
# Cấp quyền thực thi nếu cần
chmod +x run.sh

# 1. Cài đặt các thư viện phụ thuộc (pub get)
./run.sh deps

# 2. Phân tích mã nguồn và kiểm tra cảnh báo (analyze)
./run.sh analyze

# 3. Chạy ứng dụng trên thiết bị thật / máy ảo (Tự động adb reverse port 8080)
./run.sh run

# 4. Chạy bộ kiểm thử tự động (unit + contract tests)
./run.sh test

# 5. Đóng gói file cài đặt Release APK
./run.sh apk
```

### Cách 2: Lệnh Flutter Tiêu Chuẩn

```bash
# Cài đặt dependencies
flutter pub get

# Chạy trên thiết bị Android/iOS kết nối
flutter run

# Chạy trên trình duyệt Web (Chrome)
flutter run -d chrome
```

---

## 🧪 Kiểm Thử Tự Động

### Unit + Contract Tests (Mặc định - không cần backend)

```bash
flutter test
# Kết quả mong đợi: 0 fail (e2e tests bị skip)
```

### Contract Tests Riêng Biệt

```bash
# Identity contract (auth, profile, KYC, money request, sessions)
flutter test test/contract/identity_contract_test.dart

# Money movement contract (transfer, transaction, idempotency)
flutter test test/contract/money_movement_contract_test.dart

# Backend inventory contract (đọc source BE, đối chiếu endpoint)
flutter test test/contract/backend_inventory_test.dart
```

### E2E Tests (Cần Backend Chạy)

```bash
# Cần backend stack chạy tại :8080 (API Gateway, PostgreSQL, Redis, Kafka)
# Chỉ chạy khi cần nghiệm thu tích hợp thực sự
RUN_E2E=true flutter test --tags e2e
```

> **Lưu ý:** `flutter test` mặc định **KHÔNG chạy** các test E2E (36 test trong `be_integration_test.dart`) vì cần backend thật. Các test này bị skip với lý do rõ ràng.

---

## 📑 Tài Liệu Tham Khảo (Đã Đính Chính)

| File | Trạng Thái | Ghi Chú |
|------|------------|---------|
| `mobile/README.md` | **ĐÃ ĐỊNH CHÍNH** | Phiên bản này - phản ánh thực tế code & backend |
| `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md` | **SUPERSEDED** | Đặc tả lịch sử (ngày 05/09/2026), KHÔNG phản ánh backend hiện tại |
| `mobile/docs/API_INTEGRATION_GUIDE.md` | **SUPERSEDED** | Hướng dẫn API cũ, nhiều endpoint không tồn tại |
| `mobile/docs/BAO_CAO_KIEM_TRA_LUONG_NUT_BAM.md` | **SUPERSEDED** | Báo cáo "51/51 màn hình" - đúng về UI nhưng nhiều màn gọi API không tồn tại |
| `.agents_workspace/01_ISSUES_AND_TASKS.md` | **AUDIT GỐC** | Sổ lỗi đầy đủ, phân công task, bằng chứng |
| `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md` | **AUDIT CUỐI** | Verdict trước/sau, bảng claim, issue đã đóng/chưa đóng |

---

## ⚠️ Backend Gaps (Quantified)

Dưới đây là các tính năng mobile **ĐÃ CÓ UI** nhưng **BACKEND KHÔNG CÓ API** (xem chi tiết `01_ISSUES_AND_TASKS.md` Phụ lục A):

| Tính Năng | Endpoint Mobile Gọi | Trạng Thái BE | BE-REQ | Mobile Handling |
|-----------|---------------------|---------------|--------|-----------------|
| Refresh Token | `POST /auth/refresh?refreshToken=` (query) | ❌ Sai - BE yêu cầu JSON body | - | **ĐÃ SỬA** (MOB-001) |
| OTP Đăng ký/Quên MK | `/auth/otp/*`, `/auth/forgot-password`, `/auth/reset-password` | ❌ Không tồn tại | BE-REQ-04 | Gate + hướng dẫn CSKH |
| PIN Giao dịch | `/users/pin/set`, `/users/pin/verify` | ❌ Không tồn tại | BE-REQ-03 | **CHẶN GIAO DỊCH** (MOB-002) |
| Nạp/Rút tiền | `/wallets/deposit`, `/wallets/withdraw` | ❌ Không tồn tại | BE-REQ-06 | Gate tại nút xác nhận |
| Hóa đơn/VietQR | `/bills/*`, `/payments/vietqr/*` | ❌ Không tồn tại | BE-REQ-06 | Gate tại nút xác nhận |
| Tài khoản ngân hàng | `/bank-accounts/*`, `/funding-sources` | ❌ Không tồn tại | BE-REQ-06 | Gate |
| Thụ hưởng | `/beneficiaries` | ❌ Không tồn tại | BE-REQ-06 | Gate |
| Biên lai/Xuất sao kê | `/transactions/{id}/receipt.pdf`, `/transactions/export/*` | ❌ Không tồn tại | BE-REQ-06 | Gate |
| Cấu hình hạn mức | `/config/limits*`, `/users/me/qrcode` | ❌ Không tồn tại | BE-REQ-06 | Gate / Empty state |
| Referral/Legal/Feedback | `/referrals/*`, `/legal/*`, `/feedback` | ❌ Không tồn tại | BE-REQ-06 | Gate |

**Tổng kết:** 24 endpoint ✅ / 7 endpoint ⚠️ (sai path/payload) / 38 endpoint ❌ (không tồn tại) trên 69 bề mặt API được khai báo.

---

## 🔧 Definition of Done (Đề Xuất Cho PR)

Mọi Pull Request vào repo mobile phải đạt:

- [ ] `flutter analyze` — **No issues found**
- [ ] `flutter test` — **0 fail** (e2e tests skip với lý do)
- [ ] `flutter test test/contract` — **All contract tests pass**
- [ ] Backend guard pass:
  ```bash
  git status --porcelain -- backend   # phải rỗng
  git diff --name-only -- backend     # phải rỗng
  git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
  # eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003
  ```
- [ ] Không còn call chưa gate tới endpoint không tồn tại:
  ```bash
  grep -rn "users/pin\|auth/otp\|wallets/deposit\|wallets/withdraw\|bills/\|vietqr\|bank-accounts\|funding-sources\|beneficiaries\|config/limits\|users/kyc\|receipt.pdf\|export/" lib
  # Mọi kết quả phải nằm sau BackendCapabilities hoặc có comment BE-GAP
  ```

---

## 📄 Giấy Phép

Dự án nội bộ - Sen Hồng Bank Team.