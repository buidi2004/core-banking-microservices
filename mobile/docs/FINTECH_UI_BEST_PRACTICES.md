# 🎨 Fintech Mobile UI Best Practices - Applied to SenBank

## 📋 Tổng Quan

Tài liệu này tổng hợp các nguyên tắc thiết kế fintech premium đã được áp dụng vào màn đăng nhập và trang chủ của SenBank Mobile App.

---

## 🚫 Anti-Slop Rules (Bỏ Các Pattern Lỗi Thời)

### 1. **Muddy Box Shadows → Hairline Borders**

❌ **Tránh:**
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.03), // Quá nhạt
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
]
```

✅ **Nên dùng:**
```dart
border: Border.all(
  color: AppColors.borderLight,
  width: 1.0,  // Hairline rõ ràng
)
```

**Lý do:**
- Shadows opacity <0.05 tạo "muddy" effect không rõ ràng
- Hairline borders cho depth perception tốt hơn
- Giảm overdraw 8-12 layers
- Tăng performance đáng kể

---

### 2. **Gradient Overuse → Purposeful Color**

❌ **Tránh:**
```dart
// Gradient ở mọi nơi không cần thiết
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [color1, color2],
  ),
)
```

✅ **Nên dùng:**
```dart
// Flat color, gradient chỉ cho hero moments
decoration: BoxDecoration(
  color: Colors.white,  // Simple & clear
)
```

**Exceptions (Được phép dùng gradient):**
- Hero header (VietnamHeroHeader) ✅
- Bottom navigation bar ✅
- Card backgrounds khi là design focal point ✅

---

### 3. **Tiny Labels → Readable Sizes**

❌ **Tránh:**
```dart
style: TextStyle(
  fontSize: 9,  // Quá nhỏ
  letterSpacing: 2.0,  // Letter-spaced uppercase
)
```

✅ **Nên dùng:**
```dart
style: AppTypography.bodySmall(color: AppColors.textPrimaryLight)
    .copyWith(
  fontSize: 12,  // Minimum readable
  fontWeight: FontWeight.w500,
)
```

---

### 4. **Icon Cards → Meaningful Layout**

❌ **Tránh:**
```dart
// Grid vô hồn với icon giống nhau
Row(
  children: services.map((s) => IconCard(icon: s.icon)).toList(),
)
```

✅ **Nên dùng:**
```dart
// Layout có hierarchy rõ ràng
SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    childAspectRatio: 0.85,  // Proportions matter
  ),
  // Each service has clear icon, label, touch target
)
```

---

## ✅ Apple HIG Compliance

### 1. **Touch Targets**

**Minimum:** 44x44pt (≈44dp)  
**Recommended:** 48-56dp

**Đã áp dụng:**
```dart
// Service cards
Container(
  width: 52,   // Icon container
  height: 52,
  // + InkWell padding 4dp = 60dp total ✅
)

// Biometric button
Container(
  width: 56,
  height: 56,
  // + Padding 20dp = 96dp total ✅
)

// Login button
SizedBox(
  height: 52,  // ✅
  child: ElevatedButton(...),
)
```

---

### 2. **Haptic Feedback Hierarchy**

```dart
// Lightweight navigation
HapticFeedback.selectionClick()
// Use: Tab switching, toggle buttons, checkboxes

// Standard tap
HapticFeedback.lightImpact()
// Use: List item tap, service card tap, search

// Important action
HapticFeedback.mediumImpact()
// Use: Transfer, Deposit, Withdraw, Login

// Critical success
HapticFeedback.heavyImpact()
// Use: Biometric success, transaction complete

// Error
HapticFeedback.vibrate()
// Use: Failed validation, error state
```

**Nguyên tắc:**
- Càng quan trọng → feedback càng mạnh
- Financial actions → medium+
- Authentication success → heavy
- Navigation → light

---

### 3. **Typography Scale**

```dart
// Display (Hero numbers)
AppTypography.displayLarge()   // 32px, Bold
AppTypography.displayMedium()  // 24px, Bold

// Titles (Section headers)
AppTypography.titleLarge()     // 18px, Semibold
AppTypography.titleMedium()    // 16px, Semibold

// Body (Content)
AppTypography.bodyLarge()      // 16px, Regular
AppTypography.bodyMedium()     // 14px, Regular
AppTypography.bodySmall()      // 13px, Medium

// Financial (Tabular)
AppTypography.financialFigures(
  fontFeatures: [FontFeature.tabularFigures()],
)
```

**Apple HIG Names:**
```dart
// iOS native styles
AppTypography.largeTitle()     // 34px
AppTypography.title1()         // 28px
AppTypography.headline()       // 17px
AppTypography.body()           // 17px
AppTypography.footnote()       // 13px
AppTypography.caption1()       // 12px
```

---

## 💰 Fintech-Specific Rules

### 1. **Tabular Figures (Must-Have)**

❌ **Tránh:**
```dart
Text(
  formatCurrency(balance),
  style: TextStyle(fontSize: 28),
  // Proportional numbers → layout shifts
)
```

✅ **Nên dùng:**
```dart
Text(
  formatCurrency(balance),
  style: AppTypography.financialFigures().copyWith(
    fontFeatures: const [
      FontFeature.tabularFigures(),  // Fixed-width digits
    ],
  ),
)
```

**Lợi ích:**
- 0-9 có cùng chiều rộng
- Không giật layout khi số thay đổi
- Professional financial app appearance

---

### 2. **Money Format Consistency**

```dart
// Luôn dùng CurrencyFormatter
CurrencyFormatter.formatVND(amount)
// Output: "12.580.000 ₫"

// KHÔNG hardcode
'${amount.toStringAsFixed(0)} VND'  // ❌
```

---

### 3. **Balance Visibility Toggle**

```dart
// Icon morphing
AppMorphIcon(
  icon: _hideBalance
      ? CupertinoIcons.eye_slash_fill
      : CupertinoIcons.eye_fill,
  size: 16,
  color: Colors.white,
  spring: MorphSprings.snappy,
)

// Display logic
Text(
  _hideBalance ? '••••••••' : formatCurrency(_balance),
)
```

**Best Practice:** Ẩn hiện mượt mà, không làm layout shift.

---

### 4. **Transaction Item Design**

```dart
ListTile(
  // Icon với background color semantic
  leading: CircleAvatar(
    backgroundColor: isPositive
        ? AppColors.emeraldGreen.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.12),
    child: Icon(
      isPositive
          ? CupertinoIcons.arrow_down_left   // Incoming
          : CupertinoIcons.arrow_up_right,   // Outgoing
      color: isPositive
          ? AppColors.emeraldGreenLight
          : AppColors.primaryLight,
    ),
  ),
  
  // Amount với tabular figures
  trailing: Text(
    '${isPositive ? '+' : ''}${formatVND(amount)}',
    style: AppTypography.titleMedium(
      color: isPositive ? AppColors.emeraldGreenLight : AppColors.textPrimaryLight,
    ).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  ),
)
```

---

## 🎨 Color Tokens - WCAG AA

### Text Colors (Light Mode)

```dart
// Primary text: 13.7:1 contrast ratio ✅
AppColors.textPrimaryLight = Color(0xFF0F172A)

// Secondary text: 5.8:1 ✅
AppColors.textSecondaryLight = Color(0xFF475569)

// Muted text: 4.57:1 ✅
AppColors.textMutedLight = Color(0xFF55657A)
```

### Semantic Colors

```dart
// Success (readable on light)
AppColors.successTextLight = Color(0xFF14532D)  // 8:1 ✅

// Warning (readable on light)
AppColors.warningText = Color(0xFF7C2D12)  // 6.0:1 ✅

// Error
AppColors.errorText = Color(0xFFB91C1C)  // High contrast ✅
```

### Border Colors

```dart
// Clear borders
AppColors.borderLight = Color(0xFFE2E8F0)

// Subtle dividers
AppColors.borderSubtle = Color(0xFFCBD5E1)

// Glass surfaces
AppColors.glassBorderLight = Color(0x80FFFFFF)
```

---

## 🚀 Performance Optimizations

### 1. **Cached Typography**

```dart
// AppTypography internal structure
class AppTypography {
  // Cache base styles (created once)
  static final _bodyMediumBase = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  // Only copyWith for color
  static TextStyle bodyMedium({Color? color}) =>
      color == null
          ? _bodyMediumBase
          : _bodyMediumBase.copyWith(color: color);
}
```

**Benefit:** Giảm allocation trên heap khi rebuild.

---

### 2. **Const Constructors**

```dart
// Use const khi có thể
const SizedBox(height: 110)  // ✅
const EdgeInsets.all(20)     // ✅

// List of services
final List<Map<String, dynamic>> _quickServices = const [
  // const list
];
```

---

### 3. **Remove Unnecessary Widgets**

❌ **Tránh:**
```dart
Container(
  child: Container(  // Nested unnecessary
    child: Text(...),
  ),
)
```

✅ **Nên dùng:**
```dart
Container(
  child: Text(...),
)
```

---

## 📐 Layout Principles

### 1. **8dp Grid System**

```dart
// Spacing increments
const EdgeInsets.all(8)   // Tight
const EdgeInsets.all(16)  // Standard
const EdgeInsets.all(20)  // Comfortable
const EdgeInsets.all(24)  // Spacious

// Vertical rhythm
const SizedBox(height: 8)
const SizedBox(height: 16)
const SizedBox(height: 24)
```

---

### 2. **Bottom Bar Safe Area**

```dart
// CRITICAL: Preserve bottom clearance for floating tab bar
const SliverToBoxAdapter(
  child: SizedBox(height: 110),  // Never less!
)
```

**Measurement:**
- Tab bar height: 62dp
- Bar margin: 21dp
- Extra buffer: 27dp
- **Total: 110dp**

---

### 3. **Content Width**

```dart
// Horizontal padding consistent
padding: const EdgeInsets.symmetric(horizontal: 20)

// Never edge-to-edge text (except hero)
// Always 16-24dp margins
```

---

## 🧪 Testing Guidelines

### Visual Regression

```bash
# Screenshot testing
flutter test --update-goldens
flutter test integration_test/home_screen_test.dart
```

### Accessibility

```dart
testWidgets('Touch targets are at least 44dp', (tester) async {
  // Find all buttons
  final buttons = find.byType(ElevatedButton);
  
  for (var button in buttons.evaluate()) {
    final size = tester.getSize(find.byWidget(button.widget));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  }
});
```

### Contrast

```dart
testWidgets('Text contrast meets WCAG AA', (tester) async {
  // Use contrast checker
  expect(
    contrastRatio(AppColors.textPrimaryLight, Colors.white),
    greaterThanOrEqualTo(4.5),
  );
});
```

---

## 📚 References & Tools

### Design Systems
- **Revolut**: Premium fintech UI reference
- **N26**: Clean, minimal banking
- **Chase**: Traditional bank gone digital
- **Monzo**: Friendly banking UX

### Tools
- **Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **SF Symbols**: https://developer.apple.com/sf-symbols/
- **Figma**: Design handoff tool
- **Zeplin**: Developer-designer collaboration

### Documentation
- **Apple HIG**: https://developer.apple.com/design/human-interface-guidelines/
- **Material Design 3**: https://m3.material.io/
- **WCAG 2.1**: https://www.w3.org/WAI/WCAG21/quickref/
- **Flutter Performance**: https://docs.flutter.dev/perf/best-practices

---

## 🎯 Quick Checklist (For Every Screen)

- [ ] No muddy shadows (use hairline borders)
- [ ] Touch targets ≥44dp
- [ ] Haptic feedback on all interactions
- [ ] Tabular figures for numbers
- [ ] WCAG AA contrast ratios
- [ ] Consistent spacing (8dp grid)
- [ ] Bottom bar clearance preserved
- [ ] Loading states handled
- [ ] Empty states designed
- [ ] Error states friendly

---

**Áp dụng các nguyên tắc này sẽ tạo ra fintech app chuyên nghiệp, accessible, và performant.**
