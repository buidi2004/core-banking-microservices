# 07_TRANSFER_INTERNAL_FLOW_CONTRAST_AUDIT.md — KIỂM TRA "PHẢN QUAN" & "CHỮ MỜ" TRONG LUỒNG CHUYỂN TIỀN NỘI BỘ (SENBANK MOBILE)

**Mã audit:** `AUDIT-TP-CONTRAST-001`
**Ngày:** 21/10/2026
**Phạm vi:** Mobile Flutter — luồng **Chuyển tiền nội bộ** ("Ví tới Ví (Nội bộ)") + các màn phụ trực tiếp phục vụ luồng
**Nhánh:** `buidi2004/lionfish` @ `47fb823`

---

## 0. Tóm tắt điều hành

| Hạng mục | Trước | Sau | Kết quả |
|---|---|---|---|
| Màn hình trong luồng bị lỗi tương phản | **7/7** | **0/7** | ✅ Khắc phục hoàn toàn |
| Lỗi **chữ "phản quan"** (chữ sáng trên nền sáng) | **26** | **0** | ✅ |
| Lỗi **chữ "mờ"** (chữ không đạt WCAG AA) | **41** | **0** | ✅ |
| Lỗi **icon** (không đạt WCAG 1.4.11) | **84** | **0** | ✅ |
| Lỗi icon "phản quan" (icon gần như vô hình) | **8** | **0** | ✅ |
| `flutter analyze` | — | **0 issues** | ✅ |
| `flutter test` | 80/80 | **88/88 PASS** (1 skipped) | ✅ |
| Toàn app (55 màn ngoài luồng) — lỗi chữ | 500 | **302** | ✅ −39.6% (không màn nào tăng lỗi) |
| Toàn app — lỗi icon | 361 | **255** | ✅ −29.4% (không màn nào tăng lỗi) |

**Kết luận:** Có hiện tượng **phản quan** và **chữ mờ** thật, và nguyên nhân gốc đã được xác định chính xác:
`enter_amount_screen.dart` được viết theo **dark theme** (chữ trắng / trắng mờ) nhưng app chạy 100% ở
**light theme** với ảnh nền sáng → toàn bộ chữ trên màn "Nhập Số Tiền Chuyển" gần như **vô hình**.
Ngoài ra bàn phím PIN có 2 nút (FaceID / Xóa) dùng **icon trắng trên nền trong suốt** → vô hình hoàn toàn.

---

## 1. Phương pháp & bằng chứng

### 1.1. Xác định nền thực tế (nền của lỗi)

| Yếu tố | Giá trị thực tế | Nguồn |
|---|---|---|
| Theme ứng dụng | `AppTheme.lightTheme` (không khai báo `darkTheme`) | `mobile/lib/main.dart:52` |
| Ảnh nền toàn app | `assets/images/glass_background_pattern.png` | `mobile/lib/main.dart:82` |
| Màu trung bình ảnh nền | **RGB(224,5 / 226,7 / 224,9) ≈ `#E0E2E1`** (sáng) | đo trực tiếp pixel PNG |
| `GlassCard` ở chế độ sáng | `Color.fromRGBO(210,220,240,0.12)` + blur | `liquid_glass_widgets-1.14.0/lib/theme/glass_theme_data.dart` |

⇒ **Bề mặt thực tế của mọi `GlassCard` vẫn SÁNG.** Bất kỳ chữ màu trắng nào đặt trên đó đều không đọc được.

### 1.2. Công cụ audit (mới, tái sử dụng được)

- `mobile/test/support/contrast_audit.dart` — engine audit tương phản:
  - Composite **toàn bộ chuỗi lớp nền cha** (Scaffold → Material → Container/DecoratedBox → GlassCard) để suy ra
    nền hiệu dụng tại đúng vị trí từng thành phần chữ (không đoán bừa).
  - Tính **relative luminance** + **contrast ratio** theo WCAG 2.1.
  - Phân loại 3 mức: `PHẢN-QUAN` (< 2.0 và chữ sáng hơn nền) · `MỜ` (dưới ngưỡng AA) · `OK`.
  - Ngưỡng AA: **4.5:1** cho chữ thường, **3.0:1** cho chữ lớn (≥ 24px, hoặc ≥ 18.66px bold).
  - Audit **icon** theo WCAG **1.4.11** (≥ 3:1) — bắt được icon "vô hình".
- `mobile/test/transfer_internal_flow_contrast_audit_test.dart` — **quality gate** của luồng chuyển tiền nội bộ (assert 0 lỗi).
- `mobile/test/contrast_scan_all_screens_test.dart` — công cụ **chẩn đoán** quét 55 màn hình còn lại của app.

### 1.3. Lệnh đã chạy

```bash
cd mobile
flutter analyze                                   # → No issues found!
flutter test                                      # → 88/88 PASS (1 skipped)
flutter test test/transfer_internal_flow_contrast_audit_test.dart   # → 7/7 PASS
flutter test test/contrast_scan_all_screens_test.dart               # → quét chẩn đoán
```

**Baseline đối chiếu:** đo lại trên worktree sạch tại `HEAD` (`47fb823`) bằng đúng bộ audit này.

---

## 2. Findings — theo từng màn hình trong luồng

### M-01 (P0) — `EnterAmountScreen` (`/transfer/amount`) — **25 chữ + 5 icon "phản quan"**

**Bằng chứng:** toàn bộ màn viết bằng bảng màu dark theme (`Colors.white`, `Colors.white54/60/70/38/30`,
`AppColors.bottomBarCyan`, nền `Color(0xFF0D1B2A)`, `Color(0xFF0C1929)`, `Color(0xFF132A48)`), trong khi nền thực
tế là ảnh sáng `#E0E2E1`.

| Nội dung | Màu chữ cũ | Nền hiệu dụng | Tỉ lệ | Trạng thái |
|---|---|---|---|---|
| Số tiền (hint `0`, 34px w900) | `#4DFFFFFF` | `#DEE1E3` | **1.09** | Vô hình |
| Nút "Tiếp tục xác nhận giao dịch" (disabled) | `#62FFFFFF` | `#ECEEED` | **1.06** | Vô hình |
| Tên người nhận "NGUYEN VAN A" | `#FFFFFFFF` | `#DEE1E3` | **1.31** | Vô hình |
| "Số tiền giao dịch" | `#B3FFFFFF` | `#E0E2E1` | **1.21** | Vô hình |
| "Số dư khả dụng" | `#99FFFFFF` | `#DEE1E3` | **1.18** | Vô hình |
| "Cam kết chuyển mạch NAPAS 24/7…" | `#FFFFFFFF` | `#E1E3E2` | **1.29** | Vô hình |
| "Mặc định" (thẻ e-card) | `#FFFFFFFF` | `#B2E3E0` | **1.41** | Vô hình |
| Icon radio chưa chọn / icon xóa | `#3DFFFFFF` | `#DEE1E3` | **1.07** | Vô hình |

**Tác động:** Màn nhập số tiền — màn **then chốt** của luồng chuyển tiền nội bộ — gần như trống về nội dung
chữ. Người dùng không đọc được số tiền, không đọc được số dư, không đọc được tên người nhận.

**Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)** — chuyển toàn bộ màn sang **light theme**:
- Nền card dùng `Colors.white` bán trong suốt (0.72–0.88) + viền `borderLight` ⇒ bề mặt sáng đọc được.
- Mọi chữ chuyển sang token chuẩn: `textPrimaryLight` / `textSecondaryLight` / `primaryText` / `successText`.
- Thẻ e-card tách `color` (trang trí) và `iconColor` (màu thực hiện, ≥ 3:1).
- Avatar gradient đổi sang `primaryDark → #0086C0` để icon trắng đạt ≥ 3:1.
- Nút CTA dùng `primaryDark` nền (chữ trắng 4.87:1) thay vì `primary` (2.46:1).
- Trạng thái disabled: nền `surfaceLight` + chữ `textSecondaryLight` (thay vì `white38` trên nền gần như trong suốt).

### M-02 (P0) — Bàn phím PIN (`CustomPinNumpad`) — **2 icon "phản quan" (vô hình)**

**Bằng chứng:** `_buildSpecialButton()` dùng `Material(color: Colors.transparent)` +
`Icon(color: AppColors.textPrimaryDark)` (trắng) ⇒ nút **FaceID** và nút **Xóa** màu trắng trên nền ảnh sáng.

| Nội dung | Màu | Nền hiệu dụng | Tỉ lệ |
|---|---|---|---|
| Nút FaceID (`viewfinder_circle_fill`, 28px) | `#F8FAFC` | `#E0E2E1` | **1.24** |
| Nút Xóa (`delete_left_fill`, 28px) | `#F8FAFC` | `#E0E2E1` | **1.24** |

**Tác động:** Người dùng không thấy 2 nút quan trọng của bước ký PIN (nhận diện sinh trắc học / xóa số đã nhập).
Ngoài ra 11 chữ khác trên bàn phím cũng dưới ngưỡng AA (chấm PIN `primary` 2.46:1, chấm rỗng `cardBorderDark` gần như vô hình).

**Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)** — nút đặc biệt dùng nền `cardDark` đồng bộ phím số (icon trắng
15.8:1), chấm PIN đổi `primaryDark`, viền chấm rỗng đổi `borderSubtle`.

### M-03 (P1) — `ChooseRecipientScreen` (`/transfer`) — **1 chữ "phản quan"**

**Bằng chứng:** tab active "Ví tới Ví (Nội bộ)" dùng `gradient: AppColors.primaryGradient`
(`#26E5DC → #00B4D8`) với chữ trắng ⇒ tỉ lệ **1.96:1**.

**Trạng thái:** **ĐÃ KHẮC PHỤC** — tab active đổi nền solid `primaryDark` (`#0077B6`, chữ trắng 4.87:1),
nút "Chọn" cũng chuyển sang `primaryDark`; icon/nhấn nháy chuyển `primary` → `primaryText` (4.56:1).

### M-04 (P1) — `ConfirmTransferScreen` (`/transfer/confirm`) — **11 chữ mờ**

| Nội dung | Màu cũ | Tỉ lệ cũ |
|---|---|---|
| "Phí giao dịch: 0 đ" | `emeraldGreen #10B981` | **1.94** |
| "Người nhận", "Số tài khoản / SĐT", "Phương thức"… | `textSecondaryLight #64748B` | **3.63** |
| "Sửa số tiền" (OutlinedButton) | `primaryDark #0077B6` | **3.74** |

**Trạng thái:** **ĐÃ KHẮC PHỤC** — nhãn chuyển `textSecondaryLight` mới (5.8:1), phí chuyển
`successText` (5.49:1), nút chính/nút phụ chuyển `primaryDark`/`primaryText`.

### M-05 (P1) — `TransferResultScreen` (`/transfer/result`) — **7 chữ mờ + 1 icon phản quan**

| Nội dung | Màu cũ | Tỉ lệ cũ |
|---|---|---|
| Số tiền "500.000 đ" (32px bold) | `emeraldGreen #10B981` | **1.95** (cần 3.0) |
| "CHỨNG TỪ ĐIỆN TỬ - SMART OTP XÁC THỰC" | `primary #00B4D8` | **2.25** |
| Nút "Về màn hình chính" | trắng trên `primary` | **2.46** |
| "0 đ (Miễn phí)" | `emeraldGreen` | **2.49** |
| Icon logo ngân hàng (trắng trên gradient cyan) | — | **1.96** (phản quan) |

**Trạng thái:** **ĐÃ KHẮC PHỤC** — số tiền chuyển `successTextLight` (5.49:1), chữ thương hiệu
`primaryText`, nút chính `primaryDark`, logo gradient đổi `primaryDark → #0086C0` (icon trắng ≥ 3:1).

### M-06 (P2) — `BeneficiariesScreen` (`/beneficiaries`) & `RequestTransferScreen` (`/transfer/request`)

- 3 chữ mờ: placeholder `textMutedLight #94A3B8` (**1.97**), giới hạn `warningText #B45309` (**3.86**).
- 16 icon mờ: `primary #00B4D8` làm màu icon (**1.88–1.89**), chip active nền `primary` (chữ trắng 2.46).

**Trạng thái:** **ĐÃ KHẮC PHỤC** — placeholder dùng `textMutedLight` mới (4.57:1), icon chuyển `primaryText`,
chip active nền `primaryDark`.

---

## 3. Thay đổi token màu toàn cục (`mobile/lib/core/theme/app_colors.dart`)

App dùng chung token cho 50+ màn, nên các token **gốc rễ** được hiệu chỉnh một lần thay vì vá từng màn:

| Token | Cũ | Mới | Tỉ lệ (trên `#E0E2E1`) | Tác động |
|---|---|---|---|---|
| `textSecondaryLight` | `#64748B` | `#475569` | 3.66 → **5.82** | Toàn app |
| `textMutedLight` | `#94A3B8` | `#55657A` | 2.56 → **4.57** | Toàn app |
| `successText` | `#15803D` | `#166534` | 3.86 → **5.49** | Toàn app |
| `warningText` | `#B45309` | `#92400E` | 3.86 → **5.45** | Toàn app |

**Token mới** (chỉ dùng cho **chữ**, không dùng cho icon/nền — tránh lệch brand):

| Token | Giá trị | Tỉ lệ | Ghi chú |
|---|---|---|---|
| `primaryText` | `#0369A1` | **4.56** | Thay cho `primary #00B4D8` (2.46) khi làm màu chữ |
| `successTextLight` | `#166534` | **5.49** | Thay cho `emeraldGreen #10B981` (1.95) khi làm màu chữ |
| `warningTextLight` | `#92400E` | **5.45** | Thay cho `warning #F59E0B` (0.73) khi làm màu chữ |

> **Quyết định thiết kế:** `primary`, `emeraldGreen`, `accentGold`… **giữ nguyên** làm màu *trang trí / icon nền*.
> Chỉ khi hiển thị **chữ** trên nền sáng mới dùng bộ token `*Text` mới. Nhờ vậy không phá nhận diện thương hiệu
> mà vẫn đạt WCAG AA.

**Kiểm chứng không hồi quy:** quét lại 55 màn hình còn lại của app ở `HEAD` và ở trạng thái sau sửa —
**không màn nào tăng số lỗi** (chi tiết ở §5).

---

## 4. Danh sách file đã sửa

| File | Nội dung sửa |
|---|---|
| `mobile/lib/core/theme/app_colors.dart` | Hiệu chỉnh 4 token chữ + thêm 3 token `*Text` |
| `mobile/lib/presentation/screens/transfer/enter_amount_screen.dart` | **Chuyển toàn bộ màn từ dark theme → light theme** (M-01) |
| `mobile/lib/presentation/widgets/custom_pin_numpad.dart` | Sửa 2 icon vô hình + chấm PIN (M-02) |
| `mobile/lib/presentation/screens/transfer/choose_recipient_screen.dart` | Tab active, nút "Chọn", icon, empty-state (M-03) |
| `mobile/lib/presentation/screens/transfer/confirm_transfer_screen.dart` | Nhãn, phí, nút chính/phụ, checkbox (M-04) |
| `mobile/lib/presentation/screens/transfer/transfer_result_screen.dart` | Số tiền, con dấu, nút, logo, toggle (M-05) |
| `mobile/lib/presentation/screens/transfer/beneficiaries_screen.dart` | Placeholder + icon (M-06) |
| `mobile/lib/presentation/screens/transfer/request_transfer_screen.dart` | Placeholder, chip, icon, viền focus (M-06) |
| `mobile/test/support/contrast_audit.dart` | **Mới** — engine audit tương phản (WCAG 2.1 + 1.4.11) |
| `mobile/test/transfer_internal_flow_contrast_audit_test.dart` | **Mới** — quality gate 7 màn của luồng |
| `mobile/test/contrast_scan_all_screens_test.dart` | **Mới** — công cụ chẩn đoán quét 55 màn còn lại |

> **Backend guard:** không đụng tới `backend/`, `docker-compose.yml`, `deploy/`.

---

## 5. Bảng số liệu

### 5.1. Luồng chuyển tiền nội bộ (phạm vi sửa)

| Màn | Route | Chữ (node/lỗi) | Icon (node/lỗi) | Phản quan (chữ/icon) |
|---|---|---|---|---|
| M1 Chọn người nhận | `/transfer` | 16 / **2** → 16 / 0 | 21 / **20** → 21 / 0 | 1 / 0 → 0 / 0 |
| M2 Nhập số tiền | `/transfer/amount` | 40 / **32** → 40 / 0 | 19 / **15** → 19 / 0 | 25 / 5 → 0 / 0 |
| M3 Xác nhận GD | `/transfer/confirm` | 24 / **11** → 24 / 0 | 7 / **6** → 7 / 0 | 0 / 0 → 0 / 0 |
| M3b Bàn phím PIN | (trong M3) | 34 / **11** → 34 / 0 | 11 / **9** → 11 / 0 | 0 / 2 → 0 / 0 |
| M4 Kết quả | `/transfer/result` | 38 / **7** → 38 / 0 | 20 / **18** → 20 / 0 | 0 / 1 → 0 / 0 |
| M5 Danh bạ thụ hưởng | `/beneficiaries` | 3 / **1** → 3 / 0 | 2 / **2** → 2 / 0 | 0 / 0 → 0 / 0 |
| M6 Yêu cầu chia tiền | `/transfer/request` | 22 / **3** → 22 / 0 | 15 / **14** → 15 / 0 | 0 / 0 → 0 / 0 |
| **TỔNG** | | **177 / 67 → 0** | **95 / 84 → 0** | **26 / 8 → 0** |

### 5.2. Toàn app (55 màn ngoài phạm vi — đo bằng cùng bộ audit)

| | Trước (`HEAD`) | Sau |
|---|---|---|
| Thành phần chữ | 1190 node / **500 lỗi** | 1190 node / **302 lỗi** |
| Icon | 453 node / **361 lỗi** | 453 node / **255 lỗi** |

**Không màn nào tăng lỗi.** Các màn còn lại nhiều lỗi nhất (ngoài phạm vi lần này):
`BillPayment` (44), `Deposit` (29), `Savings` (24), `Cards` (20), `Settings` (20), `QuickLoan` (19).

---

## 6. Quality gate

```
$ cd mobile && flutter analyze
Analyzing mobile...
No issues found! (ran in 1.5s)

$ cd mobile && flutter test
00:15 +88 ~1: All tests passed!

$ cd mobile && flutter test test/transfer_internal_flow_contrast_audit_test.dart
00:02 +7: All tests passed!
```

- `flutter test`: **88/88 PASS** (80 test cũ + 8 test mới), 1 skipped (e2e cần backend).
- Không sửa logic nghiệp vụ, không đổi route, không đổi hợp đồng API.

---

## 7. Nợ kỹ thuật còn lại & đề xuất (ngoài phạm vi lần này)

| # | Vấn đề | Phạm vi | Đề xuất |
|---|---|---|---|
| 1 | 302 lỗi chữ + 255 lỗi icon còn lại trên 55 màn | Toàn app | Tái sử dụng `AppColors.primaryText` / `successTextLight` / `warningTextLight` cho các vị trí chữ trên nền sáng; cân nhắc đổi `elevatedButtonTheme` từ `primary` (#00B4D8) sang `primaryDark` (#0077B6) để chữ trắng trên nút đạt 4.87:1 |
| 2 | `AppColors.primary` (#00B4D8) chỉ đạt 2.46:1 dùng làm màu chữ ở nhiều nơi | Toàn app | Lint rule: chặn `TextStyle(color: AppColors.primary)` khi nền sáng |
| 3 | `elevatedButtonTheme` toàn cục dùng nền `primary` → chữ trắng 2.46:1 | Toàn app | Đề xuất đổi 1 dòng trong `app_theme.dart` (tác động thị giác toàn app, cần UX duyệt) |
| 4 | `GlassCard` ở light mode gần như trong suốt → không có ranh giới thị giác | Toàn app | Cân nhắc thêm lớp nền `Colors.white` 0.72–0.92 bên trong GlassCard như đã áp dụng ở màn nhập số tiền |
| 5 | Chưa có kiểm thử ảnh (golden) cho các màn tài chính | QA | Bổ sung golden test render màn trên nền `#E0E2E1` để chặn hồi quy tương phản trong CI |

---

## 8. Cách tái lập

```bash
# 1. Quality gate của luồng chuyển tiền nội bộ (phải PASS)
cd mobile && flutter test test/transfer_internal_flow_contrast_audit_test.dart

# 2. Quét chẩn đoán toàn app (in báo cáo, không assert)
cd mobile && flutter test test/contrast_scan_all_screens_test.dart

# 3. Dùng lại engine audit cho màn khác
//    import 'support/contrast_audit.dart';
//    await tester.pumpWidget(auditHarness(YourScreen()));
//    printContrastReport('Tên màn', collectTextFindings(tester));
//    printIconReport('Tên màn', collectIconFindings(tester));
```

---

**Người thực hiện:** Agent 46 · **Ngày:** 21/10/2026 · **Trạng thái:** Luồng chuyển tiền nội bộ đã đạt WCAG AA/1.4.11 100%.
