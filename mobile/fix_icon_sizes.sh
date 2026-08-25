#!/bin/bash
# Fix all remaining TypeScript errors related to icon sizes

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Fixing icon size types ==="

# Get list of all .tsx files with errors
files=(
  "src/screens/BillInputScreen.tsx"
  "src/screens/BillPaymentScreen.tsx"
  "src/screens/ChooseRecipientScreen.tsx"
  "src/screens/EnterAmountScreen.tsx"
  "src/screens/NotificationsScreen.tsx"
  "src/screens/PromotionsScreen.tsx"
  "src/screens/QRMyScreen.tsx"
  "src/screens/RequestTransferScreen.tsx"
  "src/screens/ScanQRScreen.tsx"
  "src/screens/SearchScreen.tsx"
  "src/screens/TransferResultScreen.tsx"
  "src/screens/ForgotPinScreen.tsx"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        # Replace numeric sizes with string sizes
        sed -i 's/size={16}/size="xs"/g' "$file"
        sed -i 's/size={20}/size="sm"/g' "$file"
        sed -i 's/size={22}/size="sm"/g' "$file"
        sed -i 's/size={24}/size="md"/g' "$file"
        sed -i 's/size={26}/size="md"/g' "$file"
        sed -i 's/size={28}/size="lg"/g' "$file"
        sed -i 's/size={32}/size="lg"/g' "$file"
    fi
done

echo ""
echo "=== Checking ForgotPinScreen for PinDot size issue ==="
grep -n "PinDot.*size" src/screens/ForgotPinScreen.tsx | head -5

echo ""
echo "=== Running TypeScript check ==="
npx tsc --noEmit 2>&1
