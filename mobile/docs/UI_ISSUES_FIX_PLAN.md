# 🔧 UI ISSUES FIX PLAN

**Phát hiện:** 05/11/2026  
**Priority:** HIGH - Ảnh hưởng UX

---

## 🚨 VẤN ĐỀ PHÁT HIỆN

### 1. **HARD CORNERS - BorderRadius < 8dp** (10 files) ⚠️

Các file có góc quá cứng (2-6dp):

| File | Line | Current | Should Be |
|------|------|---------|-----------|
| `terms_of_service_screen.dart` | 483 | `circular(2)` | `circular(12)` |
| `transfer_result_screen.dart` | 176 | `circular(2)` | `circular(12)` |
| `promotions_screen.dart` | 1537 | `circular(2)` | `circular(12)` |
| `promotions_screen.dart` | 2914 | `circular(2)` | `circular(12)` |
| `identity_document_screen.dart` | 482 | `circular(6)` | `circular(12)` |
| `transaction_detail_screen.dart` | 159 | `circular(2)` | `circular(12)` |
| `cards_screen.dart` | 316 | `circular(4)` | `circular(12)` |
| `savings_detail_screen.dart` | 106 | `circular(2)` | `circular(12)` |
| `quick_loan_screen.dart` | 879 | `circular(2)` | `circular(12)` |
| `savings_screen.dart` | 277 | `circular(2)` | `circular(12)` |

**Impact:** UI trông cứng nhắc, không hiện đại

---

### 2. **CONTAINERS WITHOUT BORDER RADIUS** (5 files) ⚠️

Containers có `shape: BoxShape.circle` (OK) hoặc thiếu borderRadius:

| File | Line | Issue |
|------|------|-------|
| `forgot_password_screen.dart` | 76 | Circle icon (OK) |
| `forgot_password_screen.dart` | 217 | Warning box cần borderRadius |
| `forgot_password_screen.dart` | 274 | Icon container (OK - circle) |
| `forgot_password_screen.dart` | 305 | Icon container (OK - circle) |
| `forgot_password_screen.dart` | 340 | Icon container (OK - circle) |

**Impact:** Một số card/box trông vuông góc

---

### 3. **TEXT OVERFLOW** (nhiều files) ⚠️

Text widgets không có `maxLines` hoặc `overflow`:

**High Risk Files:**
- `forgot_password_screen.dart`
- `login_screen.dart`
- `home_screen.dart`
- `transfer_*_screen.dart`

**Impact:** Text có thể bị tràn ra ngoài layout trên màn hình nhỏ

---

### 4. **TEXTFIELD SQUARE CORNERS** (1 file) ⚠️

| File | Issue |
|------|-------|
| `live_chat_screen.dart` | TextField không có borderRadius |

**Impact:** Input field trông cũ kỹ

---

## 🎯 FIX STRATEGY

### Phase 1: Hard Corners (Quick Wins - 15 phút)

```dart
// OLD
borderRadius: BorderRadius.circular(2)
borderRadius: BorderRadius.circular(4)
borderRadius: BorderRadius.circular(6)

// NEW
borderRadius: BorderRadius.circular(12) // Modern standard
```

### Phase 2: Missing Border Radius (10 phút)

```dart
// Add to warning boxes
decoration: BoxDecoration(
  color: AppColors.warningBg,
  borderRadius: BorderRadius.circular(12), // ADD THIS
  border: Border.all(color: AppColors.warningBorder),
)
```

### Phase 3: Text Overflow Protection (20 phút)

```dart
// OLD
Text('Long text that might overflow...')

// NEW
Text(
  'Long text that might overflow...',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)

// For multi-line
Text(
  'Long text...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### Phase 4: TextField Corners (5 phút)

```dart
decoration: InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14), // ADD THIS
  ),
)
```

---

## 📊 Priority Matrix

| Issue | Files | Priority | Time | Impact |
|-------|-------|----------|------|--------|
| Hard corners (2-6dp) | 10 | **HIGH** | 15min | High visibility |
| Missing borderRadius | 5 | MEDIUM | 10min | Medium visibility |
| Text overflow | 30+ | MEDIUM | 20min | User experience |
| TextField corners | 1 | LOW | 5min | One screen only |

**Total Estimated Time: 50 minutes**

---

## 🔧 IMPLEMENTATION PLAN

### Step 1: Fix Hard Corners (Batch Replace)

```bash
# Replace circular(2) → circular(12)
find mobile/lib/presentation/screens -name "*.dart" \
  -exec sed -i 's/BorderRadius\.circular(2)/BorderRadius.circular(12)/g' {} \;

# Replace circular(4) → circular(12)
find mobile/lib/presentation/screens -name "*.dart" \
  -exec sed -i 's/BorderRadius\.circular(4)/BorderRadius.circular(12)/g' {} \;

# Replace circular(6) → circular(12)
find mobile/lib/presentation/screens -name "*.dart" \
  -exec sed -i 's/BorderRadius\.circular(6)/BorderRadius.circular(12)/g' {} \;
```

### Step 2: Add BorderRadius to Warning Boxes

File: `forgot_password_screen.dart` line 217

```dart
decoration: BoxDecoration(
  color: AppColors.warningBg,
  borderRadius: BorderRadius.circular(12), // ADD
  border: Border.all(color: AppColors.warningBorder),
)
```

### Step 3: Text Overflow - High Priority Only

Focus on:
- Screen titles (displayLarge, displayMedium)
- Button labels
- Card titles
- List items

```dart
// Pattern to fix
Text(
  someVariable,
  style: AppTypography.titleLarge(...),
  maxLines: 1, // ADD
  overflow: TextOverflow.ellipsis, // ADD
)
```

### Step 4: TextField in live_chat_screen.dart

```dart
decoration: InputDecoration(
  labelText: 'Nhập tin nhắn',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14), // ADD
  ),
)
```

---

## ✅ QUALITY GATES

Before committing:
- [ ] All borderRadius ≥ 8dp
- [ ] No warning boxes without borderRadius
- [ ] Critical text has overflow protection
- [ ] TextFields have rounded corners
- [ ] `flutter analyze` passes
- [ ] Visual test on 3 screen sizes

---

## 📝 NOTES

### Border Radius Standards

```dart
// Modern UI standards
Small elements (badges, chips): 8dp
Cards, containers: 12dp
TextFields: 14dp
Buttons: 12dp (or fully rounded)
Modals, dialogs: 16dp
Large panels: 20dp
```

### Text Overflow Best Practices

```dart
// Short labels (1 line)
maxLines: 1
overflow: TextOverflow.ellipsis

// Descriptions (2-3 lines)
maxLines: 2 or 3
overflow: TextOverflow.ellipsis

// Body text (no limit but with overflow)
maxLines: null
overflow: TextOverflow.fade
```

---

## 🎨 EXPECTED VISUAL CHANGES

### Before
- ❌ Hard corners (2-6dp) - looks outdated
- ❌ Square boxes - rigid appearance
- ❌ Text overflow - breaks layout
- ❌ Square textfields - old design

### After
- ✅ Soft corners (12dp) - modern look
- ✅ Rounded boxes - friendly appearance
- ✅ Text ellipsis - clean layout
- ✅ Rounded textfields - iOS-like

---

**Ready to fix? Let's start with Phase 1 (Hard Corners) - Quick win!**
