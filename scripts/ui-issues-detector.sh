#!/bin/bash

echo "🔧 UI ISSUES DETECTOR - Deep Scan"
echo "=================================="
echo ""

# 1. Text Overflow Issues
echo "📝 1. TEXT OVERFLOW ISSUES:"
echo "----------------------------"
echo "Scanning for Text widgets without overflow protection..."

find mobile/lib/presentation/screens -name "*.dart" -exec grep -l "Text(" {} \; | while read file; do
  # Count Text widgets in file
  total=$(grep -c "Text(" "$file" 2>/dev/null || echo 0)
  # Count Text with overflow protection
  protected=$(grep -c "maxLines\|overflow\|TextOverflow" "$file" 2>/dev/null || echo 0)
  
  if [ $total -gt 0 ]; then
    unprotected=$((total - protected))
    if [ $unprotected -gt 5 ]; then
      echo "⚠️  $file: $unprotected/$total texts without overflow"
    fi
  fi
done
echo ""

# 2. Border Radius Issues
echo "🔲 2. BORDER RADIUS ISSUES:"
echo "----------------------------"
echo "Containers without borderRadius:"

grep -rn "decoration: BoxDecoration(" mobile/lib/presentation/screens/ --include="*.dart" -A 5 | \
  grep -B 1 "color:" | \
  grep -v "borderRadius\|shape: BoxShape.circle" | \
  grep "\.dart" | \
  head -15
echo ""

# 3. TextField Border Radius
echo "📱 3. TEXTFIELD BORDER RADIUS:"
echo "----------------------------"
find mobile/lib/presentation/screens -name "*.dart" -exec grep -l "TextField\|TextFormField" {} \; | while read file; do
  has_textfield=$(grep -c "TextField\|TextFormField" "$file")
  has_border=$(grep -c "borderRadius.*14\|borderRadius.*12\|borderRadius.*16" "$file")
  
  if [ $has_textfield -gt 0 ] && [ $has_border -eq 0 ]; then
    echo "⚠️  $file: TextField may have square corners"
  fi
done
echo ""

# 4. Button Shape
echo "🔘 4. BUTTON SHAPE ISSUES:"
echo "----------------------------"
echo "Buttons without RoundedRectangleBorder:"
grep -rn "ElevatedButton\|OutlinedButton" mobile/lib/presentation/screens/ --include="*.dart" -A 3 | \
  grep -v "RoundedRectangleBorder\|shape:" | \
  grep "Button" | \
  head -10
echo ""

# 5. Hard Corners (BorderRadius < 8)
echo "📐 5. HARD CORNERS (BorderRadius < 8dp):"
echo "----------------------------"
grep -rn "BorderRadius\.circular([0-7])" mobile/lib/presentation/screens/ --include="*.dart" | head -10
echo ""

# Summary
echo "=================================="
echo "✅ SCAN COMPLETE"
echo ""
echo "💡 RECOMMENDATIONS:"
echo "  • Text: Add maxLines + overflow: TextOverflow.ellipsis"
echo "  • Containers: BorderRadius.circular(12-16)"
echo "  • TextFields: BorderRadius.circular(14)"
echo "  • Buttons: RoundedRectangleBorder(borderRadius: 12)"
echo "  • Minimum radius: 8dp for modern look"
