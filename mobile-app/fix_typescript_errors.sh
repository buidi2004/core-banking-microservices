#!/bin/bash
# Fix all TypeScript errors related to icon sizes and imports

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Fixing App.tsx ==="
# Remove onLayout prop from AppNavigator
sed -i 's/<AppNavigator onLayout={onLayoutRootView} \/>/<AppNavigator \/>/g' App.tsx

echo ""
echo "=== Fixing icon size types ==="
# Replace numeric sizes with string sizes in all .tsx files
find src -name "*.tsx" -exec sed -i 's/size={16}/size="xs"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={20}/size="sm"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={24}/size="md"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={28}/size="lg"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={32}/size="lg"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={40}/size="lg"/g' {} \;

echo ""
echo "=== Removing remaining Ionicons imports ==="
# Find files still using Ionicons and remove import
find src -name "*.tsx" -exec grep -l "Ionicons" {} \; | while read file; do
    echo "Fixing: $file"
    # Remove Ionicons import line
    sed -i "/import.*Ionicons/d" "$file"
    # Replace any remaining Ionicons usage
    sed -i 's/Ionicons/AppIcon/g' "$file"
done

echo ""
echo "=== Running TypeScript check ==="
npx tsc --noEmit 2>&1 | head -50
