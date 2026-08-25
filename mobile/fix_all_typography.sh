#!/bin/bash
# Fix all TypeScript errors by adding Typography import

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Fixing Typography imports ==="

# List of files that need Typography import
files=(
  "src/components/AmountEntryPad.tsx"
  "src/components/BankCardRow.tsx"
  "src/components/EmptyState.tsx"
  "src/components/FAQAccordionItem.tsx"
  "src/components/GroupedListRow.tsx"
  "src/components/PrimaryButton.tsx"
  "src/components/ProviderIconGrid.tsx"
  "src/components/QuickAmountChip.tsx"
  "src/components/SearchBar.tsx"
  "src/components/SecondaryButton.tsx"
  "src/navigation/MainTabs.tsx"
  "src/screens/BillInputScreen.tsx"
  "src/screens/ChooseRecipientScreen.tsx"
  "src/screens/DepositScreen.tsx"
  "src/screens/EnterAmountScreen.tsx"
  "src/screens/ForgotPasswordScreen.tsx"
  "src/screens/ForgotPinScreen.tsx"
  "src/screens/HomeScreen.tsx"
  "src/screens/LoginScreen.tsx"
  "src/screens/OtpVerificationScreen.tsx"
  "src/screens/PaymentMethodsScreen.tsx"
  "src/screens/RequestTransferScreen.tsx"
  "src/screens/SetPinScreen.tsx"
  "src/screens/TransferConfirmScreen.tsx"
  "src/screens/TransferResultScreen.tsx"
  "src/screens/WithdrawScreen.tsx"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    # Check if Typography is already imported
    if ! grep -q "import { Typography }" "$file"; then
      # Add Typography import after the theme import
      sed -i "/from '..\/theme';/a import { Typography } from '../theme';" "$file"
      echo "Added Typography import to: $file"
    fi
  fi
done

echo ""
echo "=== Running TypeScript check ==="
npx tsc --noEmit 2>&1 | head -30
