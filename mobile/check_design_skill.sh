#!/bin/bash
# QA Script: Kiểm tra tuân thủ Design Skill (Màu sắc, Bo góc, Kính mờ, Bóng đổ)

cd "$(dirname "$0")"

echo "=== 1. Kiểm tra mã màu Hex cứng (#FFF, #000,...) ==="
grep -rnE "(color|backgroundColor|borderColor|tintColor):\s*['\"]#[0-9a-fA-F]" src --include="*.tsx" | grep -v "theme.ts" || echo "✅ PASS: 0 lỗi"

echo ""
echo "=== 2. Kiểm tra mã màu trong suốt RGBA/RGB cứng ==="
grep -rnE "rgba?\(" src --include="*.tsx" | grep -v "theme.ts" | grep -v "assets" || echo "✅ PASS: 0 lỗi"

echo ""
echo "=== 3. Kiểm tra số bo góc (borderRadius) cứng ==="
grep -rnE "borderRadius:\s*[0-9]" src --include="*.tsx" | grep -v "theme.ts" || echo "✅ PASS: 0 lỗi"

echo ""
echo "=== 4. Kiểm tra màu bóng đổ (shadowColor) cứng ==="
grep -rnE "shadowColor:\s*['\"]#" src --include="*.tsx" | grep -v "theme.ts" || echo "✅ PASS: 0 lỗi"

echo ""
echo "=== 5. Kiểm tra độ trong suốt (opacity) tĩnh ==="
grep -rnE "opacity:\s*0\.[0-9]+" src --include="*.tsx" | grep -v "theme.ts" | grep -v "Animated" || echo "✅ PASS: 0 lỗi"

echo ""
echo "Hoàn tất kiểm tra Design Skill!"
