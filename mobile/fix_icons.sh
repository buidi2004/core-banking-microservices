#!/bin/bash
# Script to replace Ionicons with AppIcon across all screens and components

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Replacing Ionicons with AppIcon ==="

# Process all .tsx files
for file in $(find src -name "*.tsx"); do
    if grep -q "Ionicons" "$file"; then
        echo "Processing: $file"
        
        # Replace the import statement
        sed -i "s/import { Ionicons } from '@expo\/vector-icons';/import { AppIcon } from '..\/..\/components\/icons\/AppIcon';/" "$file"
        
        # Replace component usage patterns
        # Pattern 1: <Ionicons name="xxx" size={yy} color={zzz} />
        sed -i 's/<Ionicons name="\([^"]*\)" size={[^}]*} color={[^}]*}/<AppIcon name="\1"/g' "$file"
        
        # Pattern 2: <Ionicons name="xxx" size={yy} color="#..." />
        sed -i 's/<Ionicons name="\([^"]*\)" size={[^}]*} color="/<AppIcon name="\1" color="/g' "$file"
        
        # Pattern 3: <Ionicons name="xxx" ... (various other patterns)
        sed -i 's/<Ionicons name="\([^"]*\)"/<AppIcon name="\1"/g' "$file"
        
        # Close tags
        sed -i 's/<\/Ionicons>/<\/AppIcon>/g' "$file"
    fi
done

echo ""
echo "=== Replacing direct Text imports with AppText ==="

# Process screen files only (not components that might need raw Text)
for file in $(find src/screens -name "*.tsx"); do
    if grep -q "^import {.*Text" "$file"; then
        echo "Processing: $file"
        
        # Add AppText import after the theme import
        if ! grep -q "AppText" "$file"; then
            sed -i "/from '..\/theme';/a import { AppText } from '../components/typography/AppText';" "$file"
        fi
        
        # Note: We cannot automatically replace all <Text> with <AppText> because
        # some screens may need raw Text for specific cases. The Typography tokens
        # are now available in theme.ts for manual use.
    fi
done

echo ""
echo "=== Check complete ==="
echo "Icons: Run 'grep -rln Ionicons src' to verify no remaining Ionicons imports"
echo "Typography: Run 'grep -rn fontSize:' to check hardcoded font sizes"
