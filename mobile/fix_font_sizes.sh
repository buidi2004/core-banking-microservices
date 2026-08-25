#!/bin/bash
# Replace all hardcoded fontSize values with Typography tokens from theme.ts

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Replacing hardcoded fontSize values ==="

# Process all screen and component files (excluding theme.ts)
for file in $(find src -name "*.tsx" | grep -v 'theme.ts'); do
    # Replace fontSize values with Typography tokens
    # Display sizes (largest)
    sed -i 's/fontSize: 40,/fontSize: Typography.displayLarge.fontSize,/g' "$file"
    sed -i 's/fontSize: 36,/fontSize: Typography.display.fontSize,/g' "$file"
    sed -i 's/fontSize: 32,/fontSize: Typography.display.fontSize,/g' "$file"
    
    # Heading sizes
    sed -i 's/fontSize: 28,/fontSize: Typography.headingLg.fontSize,/g' "$file"
    sed -i 's/fontSize: 24,/fontSize: Typography.headingXl.fontSize,/g' "$file"
    sed -i 's/fontSize: 22,/fontSize: Typography.heading.fontSize,/g' "$file"
    sed -i 's/fontSize: 20,/fontSize: Typography.headingSm.fontSize,/g' "$file"
    sed -i 's/fontSize: 18,/fontSize: Typography.bodyLg.fontSize,/g' "$file"
    sed -i 's/fontSize: 17,/fontSize: Typography.heading.fontSize,/g' "$file"
    
    # Body sizes
    sed -i 's/fontSize: 16,/fontSize: Typography.body.fontSize,/g' "$file"
    sed -i 's/fontSize: 15,/fontSize: Typography.body.fontSize,/g' "$file"
    sed -i 's/fontSize: 14,/fontSize: Typography.caption.fontSize,/g' "$file"
    sed -i 's/fontSize: 13,/fontSize: Typography.bodySm.fontSize,/g' "$file"
    
    # Caption sizes
    sed -i 's/fontSize: 12,/fontSize: Typography.caption.fontSize,/g' "$file"
    sed -i 's/fontSize: 11,/fontSize: Typography.captionSm.fontSize,/g' "$file"
    sed -i 's/fontSize: 10,/fontSize: Typography.captionXs.fontSize,/g' "$file"
done

echo ""
echo "=== Checking remaining hardcoded fontSize ==="
remaining=$(grep -rn 'fontSize:' src --include='*.tsx' | grep -v 'theme.ts' | wc -l)
echo "Remaining hardcoded fontSize: $remaining"

echo ""
echo "=== Checking fontFamily hardcodes ==="
grep -rn 'fontFamily:' src --include='*.tsx' | grep -v 'theme.ts'
