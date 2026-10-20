# 📱 Sen Hồng Bank (Fintech E-Wallet Flutter Client)

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2.svg)](https://dart.dev/)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-green.svg)](#-cấu-trúc-dự-án-clean-architecture)
[![Liquid Glass UI](https://img.shields.io/badge/UI-Liquid%20Glass%20Widgets-9cf.svg)](#-điểm-nổi-bật-về-kiến-trúc--ui)
[![Tests](https://img.shields.io/badge/QA%20Tests-6%2F6%20Passed-success.svg)](#-kiểm-thử-tự-động-qa)

Ứng dụng ví điện tử tài chính số **Sen Hồng Bank** được xây dựng trên nền tảng **Flutter 3** theo kiến trúc **Clean Architecture** và bộ widget hiệu ứng kính quang học thời thượng **`liquid_glass_widgets`**.

---

## 🌟 Điểm Nổi Bật Về Kiến Trúc & UI

1. **Giao Diện Kính Quang Học Thời Thượng (Liquid Glass UI):**
   - Tính toán và render trực tiếp bằng **Flutter fragment shader (Impeller/Skia)** thông qua cây widget thuần, khắc phục triệt để lỗi chạm xuyên (touch-through) trên Android.
   - **Phân tầng chất lượng thông minh:**
     - **Balance Card (`HomeScreen`) & Virtual Card (`CardsScreen`)**: Sử dụng `GlassQuality.premium` (hiệu ứng khúc xạ, phản chiếu specular highlight).
     - **Thanh điều hướng (`MainTabsScreen`)**: Dùng `GlassScaffold` + `GlassTabBar.bottom` với cơ chế `contentAwareBrightness` tự động tương phản màu icon tab theo nội dung nền.
     - **Lịch sử giao dịch (`TransactionHistoryScreen`)**: Sử dụng `GlassQuality.minimal` tối ưu hóa GPU, đảm bảo tốc độ cuộn mượt mà 60/120 FPS.

2. **Khả Năng Đồng Bộ & Kết Nối Backend Microservices:**
   - **Tự động Reverse Port ADB:** Script `mobile/run.sh` tự động cấu hình `adb reverse tcp:8080 tcp:8080`, cho phép thiết bị Android thật giao tiếp thẳng với Spring Cloud API Gateway qua `http://localhost:8080` mà không cần đổi IP mạng LAN.
   - **Điều phối Saga P2P Transfer:** Tích hợp trực tiếp với endpoint điều phối thanh toán phân tán `POST /payments/transfer`, tự động tra cứu `ownerId` ví người gửi/nhận và xác nhận an toàn qua mã PIN / OTP.
   - **Realtime WebSocket & Floating HUD Notification:** Kết nối Native STOMP WebSocket (`/ws-native`), tự động nhận diện và hiển thị thông báo biến động số dư dạng SMS Banking trực quan nổi trên toàn ứng dụng.

3. **Điều Hướng & Quản Lý Trạng Thái:**
   - **Stateful Shell Route (`go_router`)**: Duy trì trạng thái giao diện và vị trí cuộn khi chuyển đổi qua lại giữa 5 Tab chính.
   - **State Management:** Kết hợp linh hoạt giữa `flutter_bloc` và `Cubit` cho từng phân hệ nghiệp vụ độc lập.

4. **Bảo Mật Cấp Ngân Hàng:**
   - Bàn phím số bảo mật xáo trộn ngẫu nhiên `CustomPinNumpad`.
   - Sinh trắc học Vân tay & Khuôn mặt FaceID (`local_auth`).
   - Lưu trữ an toàn Key / Token trong phần cứng `flutter_secure_storage` (Android Keystore / iOS Keychain).
   - Bóc tách mã lỗi chi tiết từ `DioException` giúp người dùng nhận diện ngay nguyên nhân sai mật khẩu, tài khoản bị khóa hoặc vượt hạn mức.

---

## 📁 Cấu Trúc Dự Án (Clean Architecture)

```text
mobile/
├── lib/
│   ├── core/                        # Nền tảng chia sẻ toàn ứng dụng
│   │   ├── constants/               # ApiConstants (Gateway Port, WS Endpoints)
│   │   ├── network/                 # DioClient, AuthInterceptor, ErrorParser
│   │   ├── security/                # BiometricAuthService, SecureStorage
│   │   ├── theme/                   # AppColors, AppTypography, GlassThemeData
│   │   └── utils/                   # CurrencyFormatter, DateFormatter, VietQR
│   ├── data/                        # Lớp Dữ liệu (Data Layer)
│   │   ├── datasources/             # Remote API (Dio) & Local Secure Storage
│   │   ├── models/                  # DTO Models (JSON Serializable)
│   │   └── repositories/            # Triển khai Repository Contracts
│   ├── domain/                      # Lớp Nghiệp vụ (Domain Layer)
│   │   ├── entities/                # User, Wallet, Transaction, Notification
│   │   ├── repositories/            # Abstract Interfaces
│   │   └── usecases/                # Login, Transfer, Topup, GetHistory
│   └── presentation/                # Lớp Giao diện (Presentation Layer)
│       ├── bloc/cubit/              # Quản lý State (AuthBloc, WalletCubit, TransferBloc)
│       ├── routes/                  # GoRouter configuration (5 Tabs & Flow routes)
│       ├── screens/                 # 50 màn hình chức năng (10 phân hệ nghiệp vụ)
│       │   ├── shell/               # MainTabsScreen (GlassScaffold + BottomBar)
│       │   ├── home/                # HomeScreen (BalanceCard Premium)
│       │   ├── cards/               # CardsScreen (Thẻ Visa/Mastercard ảo)
│       │   ├── qr/                  # ScanQRScreen (MobileScanner), MyQRScreen (VietQR)
│       │   ├── promotions/          # PromotionsScreen (Voucher/Ưu đãi)
│       │   ├── more/                # MoreScreen (Cài đặt & Tiện ích mở rộng)
│       │   ├── auth/                # Login, Register, OTP, SetPin
│       │   ├── transfer/            # ChooseRecipient, EnterAmount, ConfirmTransfer
│       │   ├── history/             # TransactionHistory, TransactionDetail
│       │   ├── bills/               # BillPayment, BillLookup
│       │   └── settings/            # SecuritySettings, Biometrics
│       └── widgets/                 # FloatingNotificationHUD, GlassCard, CustomKeypad
├── test/
│   └── qa_commits_review_test.dart  # Bộ test tự động kiểm định QA Mobile
├── bin/
│   └── test_be.dart                 # Script kiểm thử kết nối Backend Probe
└── run.sh                           # CLI điều khiển toàn diện ứng dụng Mobile
```

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

# 4. Chạy bộ kiểm thử tự động
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

## 🧪 Kiểm Thử Tự Động (QA Tests)

Hệ thống tích hợp bộ kiểm định chất lượng tự động tại `test/qa_commits_review_test.dart`:
```bash
flutter test test/qa_commits_review_test.dart
```

**Các kịch bản kiểm thử đã được xác thực 100%:**
- **TC-NET-01:** `ApiConstants` trỏ mặc định vào API Gateway `localhost:8080` và Native WebSocket `/ws-native`.
- **TC-ERR-02:** `extractErrorMessage` bóc tách chính xác lỗi chi tiết từ Backend `DioException` thay vì báo mất mạng generic.
- **TC-ERR-03:** Bóc tách thông báo khi đăng nhập sai mật khẩu hoặc tài khoản bị khóa.
- **TC-VAL-04:** Kiểm thử tính hợp lệ của Regex định dạng số điện thoại di động Việt Nam (Đầu số 03, 05, 07, 08, 09).
- **TC-TX-01:** `TransactionRemoteDataSource` xử lý đúng cấu trúc phân trang Map V4 từ `TransactionHistoryController`.
- **TC-NOTIF-01:** `NotificationRemoteDataSource` bóc tách đúng cú pháp SMS Banking biến động số dư.

---

## 📑 Tài Liệu Tham Khảo Thêm
- [tailieuchuyendoi.md](tailieuchuyendoi.md): Toàn bộ tài liệu chi tiết 50 màn hình, sơ đồ Mermaid, bản đồ API Spring Boot và phụ lục Liquid Glass.
