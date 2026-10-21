# Báo cáo quét toàn app — Phản quan & chữ mờ (AUDIT-TP-CONTRAST-002, đợt 2)

Ngày: 2026-10-21 · Nhánh: `buidi2004/lionfish` (HEAD `47fb823`, thay đổi chưa commit)

## 1. Kết quả tổng

| Phạm vi | Trước | Sau | Giảm |
|---|---|---|---|
| **Luồng chuyển tiền nội bộ (7 màn)** | 67 lỗi chữ (26 phản quan) + 84 lỗi icon (8 phản quan) | **0 + 0** | 100% |
| **Toàn app — chữ** | 500 lỗi / 1190 phần tử | **160 lỗi** | **−68%** |
| **Toàn app — icon** | 361 lỗi / 453 phần tử | **94 lỗi** | **−74%** |

Không có màn nào bị làm xấu đi so với baseline.

## 2. Nguyên nhân gốc (đã xác định & xử lý)

1. **App chỉ chạy `AppTheme.lightTheme`** nhưng nhiều màn được viết bằng màu của dark theme
   (`Colors.white`, `Colors.white70`, `Colors.white54`) trên nền sáng → **phản quan** (tương phản 1.1–1.3:1).
2. **Màu thương hiệu dùng làm màu chữ**: `primary #00B4D8` (2.46:1), `emeraldGreen #10B981` (1.95:1),
   `accentGold #FFB300` (0.73:1), `bottomBarCyan #26E5DC` (1.21:1) → **chữ mờ**.
3. **Card tối (dark tech card)** dùng đúng màu sáng, nhưng bị các đợt chuẩn hóa toàn cục đổi sang màu tối
   → chữ tối trên nền tối.

## 3. Token màu mới (WCAG AA ≥ 4.5:1)

| Token | Màu | Dùng cho |
|---|---|---|
| `primaryText` | `#075985` | Chữ/icon xanh trên nền sáng (5.8:1) |
| `successTextLight` | `#166534` | Chữ xanh lá trên nền sáng (5.49:1) |
| `warningTextLight` | `#7C2D12` | Chữ cam trên nền sáng (6.0:1) |
| `softPurpleText` | `#6D28D9` | Chữ tím trên nền sáng (6.32:1) |
| `primaryLight` | `#26E5DC` | Chữ/icon trên **nền tối** (12.5:1) |
| `emeraldGreenLight` | `#34D399` | Chữ xanh lá trên **nền tối** (5.4:1) |
| `textSecondaryLight` | `#475569` | Chữ phụ (5.82:1) |
| `textMutedLight` | `#55657A` | Chữ mờ (4.57:1) |

**Quy tắc:** `AppColors.primary` / `emeraldGreen` / `accentGold` / `bottomBarCyan` **không bao giờ**
dùng làm màu chữ trên nền sáng — chỉ dùng cho nền, viền, gradient, icon trang trí.

## 4. Cơ chế sửa

Xây transformer **nhận biết ngữ cảnh nền** (`/tmp/opencode/fix_fg_scoped.py`):

- Dựng "scope màu" cho `Container / DecoratedBox / Material / Scaffold / Card / GlassCard`
  bằng cân bằng ngoặc trên mã đã lược chuỗi/comment.
- Nền hiệu dụng = **composite màu scope (kèm alpha) lên nền app `#E0E2E1`** rồi tính luminance.
- `L ≤ 0.185` → nền tối → dùng token sáng. `L > 0.185` → nền sáng → dùng token tối.
- Chỉ thay ở vai trò **foreground** (`TextStyle`, `Icon`, `AppTypography.*`, `GoogleFonts.*`,
  `CircularProgressIndicator`…), **tuyệt đối không chạm** `backgroundColor`, `borderColor`,
  `fillColor`, `activeColor`, `iconColor`, `side`, `gradient`…
- Hỗ trợ ternary (`isSelected ? Colors.white : AppColors.emeraldGreen`) và gradient
  (`gradient: const LinearGradient(colors: [...])`).

Sau đó chạy **vòng lặp audit → hoàn nguyên hồi quy**: mỗi lỗi "màu tối trên nền tối" được đối chiếu
manifest (`file, dòng, token gốc, token mới`) và hoàn nguyên **đúng dòng** theo nội dung chữ hiển thị.

## 5. Kiểm chứng

```bash
cd mobile
flutter analyze          # No issues found!
flutter test             # 88 pass, 1 skip
flutter build web --release   # ✓ Built build/web
```

- `test/transfer_internal_flow_contrast_audit_test.dart` — **gate cứng**: assert 0 lỗi/0 phản quan
  cho 7 màn luồng chuyển tiền nội bộ.
- `test/contrast_scan_all_screens_test.dart` — quét chẩn đoán 55 màn còn lại (không assert).

## 6. Còn tồn (163 chữ + 95 icon)

Tập trung ở các màn **trộn nền sáng/tối** mà card tối được dựng trong **hàm helper riêng** (không lồng
cú pháp với chỗ đặt chữ), nên phân tích tĩnh không suy ra được nền:

| Màn | Lỗi | Ghi chú |
|---|---|---|
| LoanSchedule | 33 | card "cơ cấu khoản vay" nền `#141F2D` |
| BillPayment | 24 | banner gradient `#132A48` + chip tháng |
| ScanQR | 18 | `_buildToolItem()` nền `#1A1B1D` |
| Lottery | 15 | card kết quả nền tối |
| Deposit | 14 | chip hạn mức nền tối |
| SavingsDetail | 13 | card tất toán nền tối |
| NfcReader | 13 | nền `#030B17` toàn màn |
| còn lại | ~33 | rải rác |

Hướng xử lý tiếp: tách các card tối thành widget riêng có tham số `dark: true`, hoặc đánh dấu
`// ignore-contrast: dark` để audit bỏ qua nhánh đó.

## 7. Đã áp dụng sau khi UX duyệt (phương án 1)

`app_theme.dart` → `elevatedButtonTheme.backgroundColor`: `primary #00B4D8` → **`primaryDark #0077B6`**.
Chữ trắng trên `#0077B6` đạt **4.87:1** (WCAG AA), trước đó chỉ 2.46:1.

Đồng bộ luôn 17 file có `backgroundColor: AppColors.primary` đặc trên nút/badge (giữ nguyên các lớp
tint `.withOpacity(0.12)` vì đó là nền sáng). Sửa thêm 2 chỗ dùng ternary bị bỏ sót:
- `scan_qr_screen.dart` — chip mode đang chọn (`isSelected ? primary : transparent`).
- `digital_signature_screen.dart` — nút "Đổi PIN OTP".

Kết quả: **163 → 160 lỗi chữ**, **95 → 94 lỗi icon**. Không còn lỗi nào trên nền `#00B4D8`.

### Còn lại cần quyết định thiết kế

Các banner gradient cyan (`#13CDDA`, `#0DB0CE`, `#0096C7`) vẫn không đạt AA với cả chữ trắng lẫn chữ tối.
Muốn xử lý phải **làm tối chính dải gradient** (ví dụ `primaryDark → #0086C0`), ảnh hưởng thẩm mỹ
banner nạp tiền / vay nhanh → cần UX duyệt riêng.
