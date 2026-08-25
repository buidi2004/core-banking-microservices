#!/bin/bash
# Add Typography import to all files that need it

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Adding Typography import to files ==="

# Process component files
for file in src/components/*.tsx; do
    if grep -q 'Typography\[' "$file" && ! grep -q "import { Typography }" "$file"; then
        echo "Adding to: $file"
        sed -i "/from '..\/theme';/a import { Typography } from '../theme';" "$file"
    fi
done

# Process screen files  
for file in src/screens/*.tsx; do
    if grep -q 'Typography\[' "$file" && ! grep -q "import { Typography }" "$file"; then
        echo "Adding to: $file"
        sed -i "/from '..\/theme';/a import { Typography } from '../theme';" "$file"
    fi
done

# Process navigation files
for file in src/navigation/*.tsx; do
    if grep -q 'Typography\[' "$file" && ! grep -q "import { Typography }" "$file"; then
        echo "Adding to: $file"
        sed -i "/from '..\/theme';/a import { Typography } from '../theme';" "$file"
    fi
done

echo ""
echo "=== Checking TypeScript ==="
npx tsc --noEmit 2>&1 | head -20
