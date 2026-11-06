# 🔧 ACTION ITEMS - Sửa Hardcoded Colors

**Priority:** HIGH  
**Ước lượng:** 30 phút  
**Files ảnh hưởng:** 3 files

---

## 📋 Danh Sách Cần Sửa

### 1. **promotions_screen.dart** (26 chỗ)

#### Gradients
```dart
// Line 54, 529
❌ const [Color(0xFF00537F), Color(0xFF007E97)]
✅ [AppColors.primaryText, AppColors.primary]

❌ [Color(0xFF005F73), Color(0xFF0A9396)]
✅ [AppColors.primaryText, AppColors.primary]
```

#### Error Colors
```dart
// Line 785, 2225, 2231
❌ Color(0xFFE11D48)
✅ AppColors.error

❌ Color(0xFF9F1239)
✅ AppColors.errorText
```

#### Background Colors
```dart
// Line 1077, 1208, 1986, 2163, 2388, 2607, 2765, 2845
❌ Color(0xF20C1E36)
✅ AppColors.cardDark

❌ Color(0xEB0A192E)
✅ AppColors.deepNavy
```

#### Overlay Colors
```dart
// Line 1445, 1852
❌ ColoredBox(color: Color(0x66030B17))
✅ ColoredBox(color: AppColors.inkNavy.withOpacity(0.4))
```

#### Border Colors
```dart
// Line 2136
❌ Color(0xFF00142A).withOpacity(0.30)
✅ AppColors.deepNavy.withOpacity(0.30)

// Line 2153, 3227
❌ Color(0x33FFFFFF)
✅ AppColors.cardBorderDark (hoặc AppColors.glassBorderDark)
```

#### Text Colors
```dart
// Line 1611
❌ Color(0xFF475569)
✅ AppColors.textSecondaryLight
```

---

### 2. **enter_amount_screen.dart** (4 chỗ)

#### Suggestion Chips
```dart
// Line 56
❌ 'color': const Color(0xFFFFA0B4),
✅ 'color': AppColors.error.withOpacity(0.8),

// Line 68
❌ 'color': const Color(0xFFFBBF24),
✅ 'color': AppColors.warning,

// Line 80
❌ 'color': const Color(0xFF38BDF8),
✅ 'color': AppColors.primaryLight,
```

#### Numpad Text
```dart
// Line 572
❌ color: const Color(0xFF0D1B2A)
✅ color: AppColors.textPrimaryLight
```

---

### 3. **config_screen.dart** (2 chỗ)

#### Card Background Gradient
```dart
// Line 435-436
❌ Color(0xFF102847),
❌ Color(0xFF0F2B48),
✅ AppColors.cardNavy,
✅ AppColors.deepNavy,
```

---

### 4. **choose_recipient_screen.dart** (Comment only)

#### Line 297-298 - Cập nhật comment
```dart
// OLD
// primaryDark (#00D4D4) để chữ trắng đạt contrast tốt.
// Pure cyan (#00FFFF) quá sáng cho background.

// NEW
// primaryDark (#0056B3) cho text trên nền sáng.
// primaryText (#003366) cho headers nghiêm túc.
```

---

## 🎯 Ưu Tiên Sửa

### Priority 1 (HIGH) - Ảnh hưởng UX
- ✅ `enter_amount_screen.dart` - Suggestion chips màu sai
- ✅ `config_screen.dart` - Card gradient không khớp palette

### Priority 2 (MEDIUM) - Consistency
- ✅ `promotions_screen.dart` - 26 hardcoded colors

### Priority 3 (LOW) - Documentation
- ✅ `choose_recipient_screen.dart` - Comment cũ

---

## 📊 Impact

**Trước sửa:**
- 30 hardcoded colors không dùng AppColors tokens
- Không tuân thủ design system
- Khó maintain khi đổi màu

**Sau sửa:**
- 100% sử dụng AppColors tokens
- Consistent với 4-color blue palette
- Dễ maintain và scale

---

## ✅ Definition of Done

- [ ] Tất cả 30 hardcoded colors đã thay bằng AppColors
- [ ] `flutter analyze` pass (no warnings)
- [ ] Visual test trên màn Promotions, Enter Amount, Config
- [ ] Màu hiển thị đúng theo mục đích (primary/primaryDark/primaryLight/primaryText)

---

**Estimated Time:** 30 phút  
**Complexity:** Easy (Find & Replace)
