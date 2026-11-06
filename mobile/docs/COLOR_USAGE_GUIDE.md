# 🎨 Color Palette Chuyên Nghiệp - 4 Màu Blue WCAG Compliant

**Ngày cập nhật:** 05/11/2026  
**Mục tiêu:** Phân cấp màu xanh theo mục đích sử dụng với WCAG AA/AAA

---

## 🎯 Bảng Màu Chính - 4 Blue Levels

| Màu | Hex | Contrast | WCAG | Mục Đích Sử Dụng |
|-----|-----|----------|------|------------------|
| **Primary** | `#0066CC` | 5.6:1 | ✅ AA | Chữ thường, link, buttons (cân bằng nhất) |
| **Primary Dark** | `#0056B3` | 7:1 | ✅ AAA | Chữ nhỏ, body text (dễ đọc hơn) |
| **Primary Light** | `#1D4ED8` | 6.7:1 | ✅ AA+ | Accent hiện đại (kiểu Tailwind) |
| **Primary Text** | `#003366` | 13:1 | ✅ AAA | Tiêu đề, headers (nghiêm túc) |

---

## 📱 Áp Dụng Theo Màn Hình

### 🔐 **Login Screen**

```dart
// Logo, App Name - Navy nghiêm túc
Text('SENBANK', style: TextStyle(
  color: AppColors.primaryText, // #003366 - 13:1
  fontSize: 24,
  fontWeight: FontWeight.w900,
))

// Subtitle - Blue AAA dễ đọc
Text('Ngân Hàng Số & Ví Điện Tử', style: TextStyle(
  color: AppColors.primaryDark, // #0056B3 - 7:1
  fontSize: 14,
))

// Login button - Primary cân bằng
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary, // #0066CC
  ),
  child: Text('Đăng nhập'),
)

// Links (Quên mật khẩu) - Primary
TextButton(
  child: Text('Quên mật khẩu?', style: TextStyle(
    color: AppColors.primary, // #0066CC - 5.6:1
  )),
)

// Config icon - Tailwind modern
Icon(CupertinoIcons.cloud_upload_fill,
  color: AppColors.primaryLight, // #1D4ED8
)
```

---

### 🏠 **Home Screen**

```dart
// Section headers "Dịch vụ nổi bật" - Navy nghiêm túc
Text('Dịch vụ nổi bật', style: AppTypography.titleLarge(
  color: AppColors.primaryText, // #003366 - 13:1
))

// Service labels (Chuyển tiền, Nạp ĐT) - Primary dark dễ đọc
Text('Chuyển tiền', style: TextStyle(
  color: AppColors.primaryDark, // #0056B3 - 7:1
  fontSize: 12,
))

// Service icons - Primary cân bằng
Icon(CupertinoIcons.paperplane_fill,
  color: AppColors.primary, // #0066CC
)

// "Xem tất cả" link - Primary
TextButton(
  child: Text('Xem tất cả', style: TextStyle(
    color: AppColors.primary, // #0066CC
  )),
)

// VND label trong hero - Tailwind accent
Text('VND', style: TextStyle(
  color: AppColors.primaryLight, // #1D4ED8
  fontWeight: FontWeight.w700,
))
```

---

### 💳 **Transaction List**

```dart
// Transaction title - Navy mạnh
Text('Chuyển tiền', style: AppTypography.titleMedium(
  color: AppColors.primaryText, // #003366
))

// Transaction description - Primary dark
Text('Gửi cho Nguyễn Văn A', style: TextStyle(
  color: AppColors.primaryDark, // #0056B3
  fontSize: 13,
))

// Amount (outgoing) - Primary
Text('-500.000 ₫', style: TextStyle(
  color: AppColors.primary, // #0066CC
  fontFeatures: [FontFeature.tabularFigures()],
))

// Status badge "Thành công" - Tailwind
Container(
  decoration: BoxDecoration(
    color: AppColors.primaryLight.withOpacity(0.1),
  ),
  child: Text('Thành công', style: TextStyle(
    color: AppColors.primaryLight, // #1D4ED8
  )),
)
```

---

### ⚙️ **Settings Screen**

```dart
// Screen title - Navy nghiêm túc
Text('Cài đặt', style: AppTypography.largeTitle(
  color: AppColors.primaryText, // #003366
))

// Section headers - Navy
Text('Bảo mật', style: AppTypography.title2(
  color: AppColors.primaryText, // #003366
))

// Setting item labels - Primary dark
Text('Thay đổi mã PIN', style: TextStyle(
  color: AppColors.primaryDark, // #0056B3
))

// Switch ON state - Primary
Switch(
  activeColor: AppColors.primary, // #0066CC
)

// Destructive action (Đăng xuất) - Keep error red
Text('Đăng xuất', style: TextStyle(
  color: AppColors.error, // Red
))
```

---

### 👤 **Profile Screen**

```dart
// User name - Navy bold
Text('Nguyễn Văn A', style: AppTypography.title1(
  color: AppColors.primaryText, // #003366
  fontWeight: FontWeight.bold,
))

// Account number label - Primary dark
Text('Số tài khoản', style: TextStyle(
  color: AppColors.primaryDark, // #0056B3
  fontSize: 13,
))

// Account number value - Primary
Text('0123456789', style: TextStyle(
  color: AppColors.primary, // #0066CC
  fontFeatures: [FontFeature.tabularFigures()],
))

// Edit profile button - Tailwind
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.primaryLight),
  ),
  child: Text('Chỉnh sửa', style: TextStyle(
    color: AppColors.primaryLight, // #1D4ED8
  )),
)
```

---

## 🎨 Gradients

### Primary Gradient (Headers, Cards)
```dart
LinearGradient(
  colors: [
    Color(0xFF0066CC), // Primary
    Color(0xFF003366), // Navy
  ],
)
```

### Balance Card Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFF003366), // Navy
    Color(0xFF0056B3), // Dark blue
    Color(0xFF0066CC), // Primary
    Color(0xFF1D4ED8), // Tailwind
  ],
)
```

### Bottom Bar Gradient (Cyan accent để nổi bật)
```dart
LinearGradient(
  colors: [
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky blue
  ],
)
```

---

## 📊 Usage Guidelines by Component

### Buttons

```dart
// Primary action - #0066CC
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
  ),
)

// Secondary action - #1D4ED8
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.primaryLight),
  ),
)

// Text button / Link - #0066CC
TextButton(
  child: Text(style: TextStyle(color: AppColors.primary)),
)
```

### Icons

```dart
// Standard icons - #0066CC
Icon(Icons.home, color: AppColors.primary)

// Accent icons (special features) - #1D4ED8
Icon(Icons.star, color: AppColors.primaryLight)

// Important icons - #003366
Icon(Icons.warning, color: AppColors.primaryText)
```

### Text Hierarchy

```dart
// H1, H2 (Display) - #003366 Navy
Text(style: AppTypography.largeTitle(color: AppColors.primaryText))

// H3, H4 (Titles) - #003366 Navy
Text(style: AppTypography.title1(color: AppColors.primaryText))

// Body text, paragraphs - #0056B3
Text(style: AppTypography.body(color: AppColors.primaryDark))

// Small text, captions - #0056B3
Text(style: AppTypography.caption1(color: AppColors.primaryDark))

// Links, highlights - #0066CC
Text(style: TextStyle(color: AppColors.primary))

// Special accents - #1D4ED8
Text(style: TextStyle(color: AppColors.primaryLight))
```

---

## ✅ WCAG Compliance Matrix

| Component | Color Used | Contrast | Pass |
|-----------|-----------|----------|------|
| Headers (H1-H2) | #003366 | 13:1 | ✅ AAA |
| Body text | #0056B3 | 7:1 | ✅ AAA |
| Links | #0066CC | 5.6:1 | ✅ AA |
| Small text (12px-) | #0056B3 | 7:1 | ✅ AAA |
| Buttons (background) | #0066CC | 5.6:1 | ✅ AA |
| Icons | #0066CC | 5.6:1 | ✅ AA |
| Accent highlights | #1D4ED8 | 6.7:1 | ✅ AA |

---

## 🚫 What NOT to Do

### ❌ Wrong Usage

```dart
// DON'T: Light blue cho tiêu đề quan trọng
Text('Số dư tài khoản', style: TextStyle(
  color: AppColors.primaryLight, // Too light for headers
))

// DON'T: Navy cho small text
Text('12px text', style: TextStyle(
  color: AppColors.primaryText, // Too dark, overwhelming
  fontSize: 12,
))

// DON'T: Primary dark cho decorative icons
Icon(Icons.star_border, 
  color: AppColors.primaryDark, // Too heavy
)
```

### ✅ Correct Usage

```dart
// DO: Navy cho headers
Text('Số dư tài khoản', style: TextStyle(
  color: AppColors.primaryText, // Perfect! 13:1
  fontSize: 18,
  fontWeight: FontWeight.bold,
))

// DO: Primary dark cho small text
Text('12px text', style: TextStyle(
  color: AppColors.primaryDark, // 7:1 AAA ✅
  fontSize: 12,
))

// DO: Primary cho decorative icons
Icon(Icons.star_border, 
  color: AppColors.primary, // Balanced
)
```

---

## 🎯 Quick Reference Cheat Sheet

```dart
// Tiêu đề màn hình, headers quan trọng
AppColors.primaryText    // #003366 (Navy - 13:1 AAA)

// Body text, mô tả, chữ nhỏ
AppColors.primaryDark    // #0056B3 (Dark Blue - 7:1 AAA)

// Buttons, links, icons chính
AppColors.primary        // #0066CC (Blue - 5.6:1 AA)

// Accents, highlights, modern touch
AppColors.primaryLight   // #1D4ED8 (Tailwind - 6.7:1 AA)

// Bottom bar (cyan để nổi bật)
AppColors.bottomBarCyan  // #06B6D4
```

---

## 📝 Migration Notes

### From Previous Cyan Palette

- Cyan #00FFFF → **#0066CC** (Primary blue)
- Cyan glow → **#1D4ED8** (Tailwind blue accent)
- Text cyan → **#0056B3** (Dark readable blue)
- Headers → **#003366** (Navy serious)

### Benefits

✅ **Better readability** - All colors pass WCAG  
✅ **Professional look** - Blue banking standard  
✅ **Clear hierarchy** - 4 levels for different purposes  
✅ **Accessibility first** - AA/AAA compliant  
✅ **Consistent brand** - Blue family throughout  

---

**Kết luận:** Sử dụng đúng màu cho đúng mục đích = UX chuyên nghiệp + Accessibility tốt! 🎨✨
