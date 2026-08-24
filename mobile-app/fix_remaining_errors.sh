#!/bin/bash
# Fix all remaining TypeScript errors related to icon sizes

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Fixing remaining icon size issues ==="

# Fix all remaining numeric sizes
find src -name "*.tsx" -exec sed -i 's/size={16}/size="xs"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={20}/size="sm"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={24}/size="md"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={28}/size="lg"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={32}/size="lg"/g' {} \;
find src -name "*.tsx" -exec sed -i 's/size={40}/size="lg"/g' {} \;

echo ""
echo "=== Removing style prop from AppIcon ==="
# Remove style prop from AppIcon usage
find src -name "*.tsx" -exec sed -i 's/<AppIcon \(.*\) style={[^}]*} \/>/<AppIcon \1 \/>/g' {} \;
find src -name "*.tsx" -exec sed -i 's/<AppIcon \(.*\) style={[^}]*}/<AppIcon \1/g' {} \;

echo ""
echo "=== Checking ForgotPinScreen ==="
head -100 src/screens/ForgotPinScreen.tsx | grep -n "size="

echo ""
echo "=== Running TypeScript check ==="
npx tsc --noEmit 2>&1 | head -30
