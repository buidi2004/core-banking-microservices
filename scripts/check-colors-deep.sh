#!/bin/bash

# Script kiểm tra chuyên sâu màu sắc trong Flutter app
# Mục đích: Đảm bảo 4 màu blue được dùng đúng theo mục đích

echo "🔍 KIỂM TRA CHUYÊN SÂU MÀU SẮC FLUTTER APP"
echo "=========================================="
echo ""
echo "📋 Quy tắc màu:"
echo "  #0066CC (primary)      → Link, buttons, icons (5.6:1 AA)"
echo "  #0056B3 (primaryDark)  → Body text, chữ nhỏ (7:1 AAA)"
echo "  #1D4ED8 (primaryLight) → Accent hiện đại (6.7:1 AA)"
echo "  #003366 (primaryText)  → Headers, tiêu đề (13:1 AAA)"
echo ""

# Đếm tổng số file
TOTAL_FILES=$(find mobile/lib/presentation/screens -name "*.dart" | wc -l)
echo "📂 Tổng số màn hình: $TOTAL_FILES files"
echo ""

# 1. Tìm tất cả hardcoded colors (không dùng AppColors)
echo "🚨 1. HARDCODED COLORS (Cần thay bằng AppColors tokens):"
echo "---"
grep -rn "Color(0x" mobile/lib/presentation/screens/ --include="*.dart" | \
  grep -v "Colors\." | \
  grep -v "AppColors" | \
  head -30
echo ""

# 2. Kiểm tra AppColors.primary usage
echo "✅ 2. AppColors.primary (#0066CC) - Buttons, Links, Icons:"
echo "---"
grep -rn "AppColors\.primary[^DLT]" mobile/lib/presentation/screens/ --include="*.dart" | \
  head -20
echo ""

# 3. Kiểm tra AppColors.primaryDark
echo "✅ 3. AppColors.primaryDark (#0056B3) - Body text:"
echo "---"
grep -rn "AppColors\.primaryDark" mobile/lib/presentation/screens/ --include="*.dart" | \
  head -15
echo ""

# 4. Kiểm tra AppColors.primaryLight
echo "✅ 4. AppColors.primaryLight (#1D4ED8) - Modern accents:"
echo "---"
grep -rn "AppColors\.primaryLight" mobile/lib/presentation/screens/ --include="*.dart" | \
  head -15
echo ""

# 5. Kiểm tra AppColors.primaryText (Navy)
echo "✅ 5. AppColors.primaryText (#003366) - Headers:"
echo "---"
grep -rn "AppColors\.primaryText" mobile/lib/presentation/screens/ --include="*.dart" | \
  head -15
echo ""

# 6. Kiểm tra các màu cũ còn sót
echo "🔴 6. MÀU CŨ CÒN SÓT (Cần loại bỏ):"
echo "---"
grep -rn "075985\|064E73\|0E7490\|00FFFF\|00D4D4\|33FFFF\|26E5DC" \
  mobile/lib/presentation/screens/ --include="*.dart" 2>/dev/null || echo "✅ Không tìm thấy màu cũ!"
echo ""

# 7. Thống kê usage
echo "📊 7. THỐNG KÊ SỬ DỤNG:"
echo "---"
PRIMARY_COUNT=$(grep -r "AppColors\.primary[^DLT]" mobile/lib/presentation/screens/ --include="*.dart" | wc -l)
PRIMARY_DARK_COUNT=$(grep -r "AppColors\.primaryDark" mobile/lib/presentation/screens/ --include="*.dart" | wc -l)
PRIMARY_LIGHT_COUNT=$(grep -r "AppColors\.primaryLight" mobile/lib/presentation/screens/ --include="*.dart" | wc -l)
PRIMARY_TEXT_COUNT=$(grep -r "AppColors\.primaryText" mobile/lib/presentation/screens/ --include="*.dart" | wc -l)

echo "AppColors.primary (Button/Link): $PRIMARY_COUNT lần"
echo "AppColors.primaryDark (Body): $PRIMARY_DARK_COUNT lần"
echo "AppColors.primaryLight (Accent): $PRIMARY_LIGHT_COUNT lần"
echo "AppColors.primaryText (Header): $PRIMARY_TEXT_COUNT lần"
echo ""

# 8. Text widget analysis
echo "📝 8. TEXT WIDGETS CẦN KIỂM TRA:"
echo "---"
echo "Tìm Text với fontSize < 14 (cần dùng primaryDark cho dễ đọc):"
grep -rn "fontSize:\s*1[0-3]" mobile/lib/presentation/screens/ --include="*.dart" | \
  grep -A 2 "color:" | head -15
echo ""

# 9. Kiểm tra headers/titles
echo "📰 9. HEADERS/TITLES (Nên dùng primaryText Navy):"
echo "---"
grep -rn "displayLarge\|displayMedium\|titleLarge\|largeTitle\|title1" \
  mobile/lib/presentation/screens/ --include="*.dart" | \
  head -15
echo ""

# 10. Tổng kết
echo "=================================="
echo "✅ HOÀN TẤT KIỂM TRA CHUYÊN SÂU"
echo "=================================="
