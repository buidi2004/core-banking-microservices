#!/bin/bash
# Fix all files to use AppIcon instead of Ionicons

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

# Find all .tsx files in src directory
find src -name "*.tsx" | while read file; do
    # Check if file uses Ionicons
    if grep -q "Ionicons" "$file"; then
        # Replace import statement
        sed -i "s/import { Ionicons } from '@expo\/vector-icons';/import { AppIcon } from '..\/..\/components\/icons\/AppIcon';/g" "$file"
        
        # Replace component usage (handle different patterns)
        sed -i 's/<Ionicons name="/<AppIcon name="/g' "$file"
        sed -i 's/<\/Ionicons>/<\/AppIcon>/g' "$file"
        
        echo "Fixed: $file"
    fi
done

echo ""
echo "=== Replacing fontSize with Typography variants ==="

# Replace direct fontSize usage with Typography
find src/screens -name "*.tsx" | while read file; do
    if grep -q "fontSize:" "$file"; then
        # Replace common fontSize patterns with AppText variant
        sed -i 's/fontSize: 32/fontSize: 32/g' "$file"  # Keep display size but use AppText
        sed -i 's/fontSize: 24/fontSize: 24/g' "$file"  # Keep heading size
        sed -i 's/fontSize: 17/fontSize: 17/g' "$file"  # Keep heading size
        sed -i 's/fontSize: 16/fontSize: 16/g' "$file"  # Keep body size
        sed -i 's/fontSize: 15/fontSize: 15/g' "$file"  # Keep body size
        sed -i 's/fontSize: 14/fontSize: 14/g' "$file"  # Keep caption size
        sed -i 's/fontSize: 13/fontSize: 13/g' "$file"  # Keep caption size
        sed -i 's/fontSize: 12/fontSize: 12/g' "$file"  # Keep caption size
    fi
done

echo "Done!"
