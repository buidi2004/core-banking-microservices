# E-Wallet Mobile App — React Native + Expo (iOS Glassmorphism)

Giao diện ví điện tử theo phong cách iOS kính mờ, đáp ứng đầy đủ Design Spec v2.

## Cấu trúc project

```
mobile-app/
├── src/
│   ├── theme.ts                    # Token trung tâm (màu, radius, spacing, shadow)
│   ├── components/
│   │   ├── PrimaryButton.tsx       # Pill button, gradient primary→blue
│   │   ├── SecondaryButton.tsx     # Outlined button, radius-md
│   │   ├── GlassCard.tsx           # BlurView wrapper, radius-lg
│   │   ├── SolidCard.tsx           # White card, radius-md
│   │   ├── StatusChip.tsx          # Success/Danger/Warning badges
│   │   ├── GroupedListRow.tsx      # iOS grouped list rows
│   │   ├── PinDot.tsx              # PIN input dots
│   │   ├── OtpBox.tsx              # OTP input boxes
│   │   ├── FloatingQRButton.tsx    # QR floating button
│   │   └── EmptyState.tsx          # Reusable empty state component
│   ├── screens/
│   │   ├── LoginScreen.tsx         # Đăng nhập
│   │   ├── RegisterScreen.tsx      # Đăng ký
│   │   ├── ForgotPasswordScreen.tsx# Quên mật khẩu
│   │   ├── SetPinScreen.tsx        # Thiết lập PIN 6 số
│   │   ├── OtpVerificationScreen.tsx # Xác thực OTP modal
│   │   ├── HomeScreen.tsx          # Dashboard (Balance Hero Card)
│   │   ├── HistoryScreen.tsx       # Lịch sử giao dịch (filter chips)
│   │   ├── ChooseRecipientScreen.tsx # Chọn người nhận (method tabs)
│   │   ├── EnterAmountScreen.tsx   # Nhập số tiền chuyển
│   │   ├── ConfirmTransferScreen.tsx # Xác nhận chuyển tiền
│   │   ├── TransferResultScreen.tsx # Kết quả giao dịch
│   │   ├── ScanQRScreen.tsx        # Quét QR camera full-screen
│   │   ├── QRMyScreen.tsx          # QR của tôi (toggle tĩnh/động)
│   │   ├── TransactionDetailScreen.tsx # Chi tiết giao dịch
│   │   ├── NotificationsScreen.tsx  # Trung tâm thông báo
│   │   ├── ProfileScreen.tsx       # Hồ sơ cá nhân (slide panel)
│   │   ├── SecuritySettingsScreen.tsx # Cài đặt bảo mật
│   │   └── DeviceManagementScreen.tsx # Quản lý thiết bị
│   ├── navigation/
│   │   ├── AppNavigator.tsx        # Stack Navigator chính
│   │   └── MainTabs.tsx            # Bottom Tab Navigator (glass)
│   └── types/
│       └── index.ts
├── App.tsx
├── package.json
└── tsconfig.json
```

## Chạy app

```bash
cd mobile-app
npm start
# hoặc
npx expo start
```

## Design Tokens (xem src/theme.ts)

| Token | Giá trị | Mô tả |
|-------|---------|-------|
| `bgBase` | `#F3F8FF` | Nền toàn app |
| `surface` | `#FFFFFF` | Card, sheet, input |
| `primary` | `#2F6FE0` | Nút chính, icon active |
| `textPrimary` | `#0B2545` | Text chính (navy) |
| `textSecondary` | `#5C7A9C` | Text phụ, caption |
| `success` | `#34C759` | Thành công |
| `danger` | `#FF3B30` | Thất bại/lỗi |
| `warning` | `#FF9F0A` | Đang xử lý |

**Border Radius:**
- `none`: 0px (header, hairline)
- `xs`: 6px (OTP boxes)
- `sm`: 12px (list rows)
- `md`: 20px (cards, buttons)
- `lg`: 28px (hero card, bottom sheet)
- `pill`: 999px (pills, avatars)

**Shadow:** tất cả dùng `shadowColor: '#3A8DFF'` — không dùng bóng đen thuần.

## 21 Màn hình đã dựng

| Nhóm | Màn hình | Đặc điểm chính |
|------|----------|----------------|
| **A** | Login, Register, ForgotPassword, SetPin, OtpVerification | Form rõ ràng, không blur, PIN dots tròn |
| **B** | HomeScreen (Dashboard) | Balance Hero Card glass, Quick Actions sheet, Promo banner |
| **C** | ChooseRecipient, EnterAmount, ConfirmTransfer, TransferResult | Input viền primary, modal OTP, StatusChip kết quả |
| **D** | ScanQR, QRMy | Camera full-screen, QR toggle tĩnh/động |
| **E** | History, TransactionDetail | Filter chips, GroupedListRow, chi tiết 2 cột |
| **F** | Notifications | Tabs "Tất cả/Chưa đọc", unread badges |
| **G** | Profile, SecuritySettings, DeviceManagement | Slide panel, EmptyState, device cards |

## Component hệ thống

- `EmptyState` — component chung cho mọi danh sách rỗng (thông báo, lịch sử, thiết bị)
- `GroupedListRow` — hàng list chuẩn iOS với border-radius động (đầu/cuối bo, giữa vuông)
- `StatusChip` — badge trạng thái pill (success/danger/warning)
- `GlassCard` — wrapper BlurView cho hiệu ứng kính mờ
- `SolidCard` — card nền trắng đơn giản
