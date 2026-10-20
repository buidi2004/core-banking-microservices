# 📱 Sen Hồng Bank (Fintech E-Wallet Flutter)

Ứng dụng ví điện tử tài chính số Sen Hồng được chuyển đổi từ React Native sang **Flutter** theo kiến trúc **Clean Architecture** và bộ widget kính quang học **`liquid_glass_widgets: ^1.3.0`**.

---

## 🌟 Điểm Nổi Bật Về Kiến Trúc & UI

1. **Loại bỏ triệt để lỗi chạm xuyên (touch-through bug) trên Android**:
   - Thay thế hoàn toàn native module `expo-liquid-glass-native` bằng `liquid_glass_widgets`.
   - Toàn bộ hiệu ứng kính mờ và khúc xạ quang học được tính toán và render trực tiếp bằng **Flutter fragment shader (Impeller/Skia)** thông qua cây widget thuần.
   - Cơ chế hit-testing đi qua gesture arena chuẩn của Flutter.
2. **Hệ thống phân tầng hiệu năng Liquid Glass**:
   - **Balance Card (`HomeScreen`) & Virtual Card (`CardsScreen`)**: Sử dụng `GlassQuality.premium` (bề mặt tĩnh trọng tâm, shader đầy đủ khúc xạ và phản xạ ánh sáng).
   - **Bottom Bar (`MainTabsScreen`)**: Dùng `GlassScaffold` + `GlassTabBar.bottom` với `contentAwareBrightness` tự động đổi màu icon tab theo nội dung cuộn bên dưới.
   - **Danh sách giao dịch (`TransactionHistoryScreen`)**: Sử dụng `GlassQuality.minimal` (BackdropFilter thuần, 0 chi phí shader tùy biến) giữ 60/120fps mượt mà khi cuộn.
3. **Điều hướng Stateful Shell Route (`go_router`)**:
   - Giữ nguyên trạng thái (State preservation) khi người dùng chuyển đổi qua lại giữa 5 Tab chính.
4. **Bảo mật & Chuẩn hóa API**:
   - Dio client với `AuthInterceptor` (Bearer token) và `IdempotencyInterceptor` (UUID tự sinh cho các request thay đổi số dư).
   - Bàn phím số bảo mật `CustomPinNumpad` và sinh trắc học FaceID/Vân tay (`local_auth`).

---

## 📁 Cấu Trúc Dự Án (Clean Architecture)

```text
lib/
├── core/
│   ├── constants/       # ApiConstants, AppConstants
│   ├── network/         # DioClient, AuthInterceptor, IdempotencyInterceptor
│   ├── theme/           # AppColors, AppTypography, AppTheme, GlassThemeData
│   └── utils/           # CurrencyFormatter, DateFormatter
├── data/
│   ├── datasources/     # Remote API & Local Secure Storage
│   └── models/          # DTO Json Serializable
├── domain/
│   ├── entities/        # UserEntity, WalletEntity, TransactionEntity
│   └── repositories/    # Abstract interfaces
├── presentation/
│   ├── routes/          # GoRouter configuration (5 Tabs & Flow routes)
│   ├── screens/         # 50 màn hình chia theo 10 phân hệ nghiệp vụ
│   │   ├── shell/       # MainTabsScreen (GlassScaffold + GlassTabBar.bottom)
│   │   ├── home/        # HomeScreen (BalanceCard Premium)
│   │   ├── cards/       # CardsScreen (Thẻ Visa/Mastercard ảo)
│   │   ├── qr/          # ScanQRScreen (MobileScanner), MyQRScreen (VietQR)
│   │   ├── promotions/  # PromotionsScreen (Vouchers)
│   │   ├── more/        # MoreScreen (Menu tiện ích & Cài đặt)
│   │   ├── auth/        # Login, Register, OTP, SetPin
│   │   ├── transfer/    # ChooseRecipient, EnterAmount, ConfirmTransfer, TransferResult
│   │   ├── history/     # TransactionHistory, TransactionDetail
│   │   ├── bills/       # BillPayment, BillLookup
│   │   ├── deposit_withdraw/ # DepositScreen, WithdrawScreen
│   │   ├── profile_ekyc/     # EKycScreen
│   │   ├── settings/    # SecuritySettingsScreen
│   │   └── support/     # HelpCenterScreen
│   └── widgets/         # CustomPinNumpad, BalanceCard, QuickActionItem
└── main.dart            # LiquidGlassWidgets.initialize() + wrap() Entry
```

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

### 1. Cài đặt dependencies:
```bash
flutter pub get
```

### 2. Chạy ứng dụng trên thiết bị / máy ảo:
```bash
# Chạy trên thiết bị kết nối (Android/iOS)
flutter run

# Chạy trên trình duyệt Web (Chrome)
flutter run -d chrome
```

---

## 📑 Tài Liệu Tham Khảo
- [tailieuchuyendoi.md](tailieuchuyendoi.md): Toàn bộ tài liệu chi tiết 50 màn hình, sơ đồ Mermaid, bản đồ API Spring Boot và phụ lục Liquid Glass.
