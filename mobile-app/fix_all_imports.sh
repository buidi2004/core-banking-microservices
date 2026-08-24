#!/bin/bash
# Auto-fix: Add AppIcon import to all files using it

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Fixing imports for AppIcon ==="

# Find all .tsx files that use AppIcon but don't import it
for file in $(grep -rl "AppIcon" src --include="*.tsx"); do
    if ! grep -q "import { AppIcon }" "$file"; then
        echo "Adding import to: $file"
        # Add import after the last import line
        sed -i "/^import.*react-native/a import { AppIcon } from '..\/components\/icons\/AppIcon';" "$file"
    fi
done

# Also fix files with wrong import paths
for file in $(grep -rl "from '..\/..\/components\/icons\/AppIcon'" src --include="*.tsx"); do
    # Fix double-dot paths for screens (need 3 dots)
    if [[ "$file" == *"src/screens/"* ]]; then
        sed -i "s|from '..\/..\/components\/icons\/AppIcon';|from '../components/icons/AppIcon';|g" "$file"
    fi
    # Fix paths for components (need 2 dots)
    if [[ "$file" == *"src/components/"* ]] && [[ ! "$file" == *"icons/"* ]]; then
        sed -i "s|from '..\/..\/components\/icons\/AppIcon';|from './icons/AppIcon';|g" "$file"
    fi
    # Fix paths for navigation
    if [[ "$file" == *"src/navigation/"* ]]; then
        sed -i "s|from '..\/..\/components\/icons\/AppIcon';|from '../components/icons/AppIcon';|g" "$file"
    fi
done

echo ""
echo "=== Fixing Ionicons usage patterns ==="

# Replace Ionicons component usage with AppIcon
for file in $(grep -rl "Ionicons" src --include="*.tsx"); do
    echo "Fixing: $file"
    
    # Replace import
    sed -i "s/import { Ionicons } from '@expo\/vector-icons';/import { AppIcon } from '..\/components\/icons\/AppIcon';/" "$file"
    
    # Replace component usage
    sed -i 's/<Ionicons name="/<AppIcon name="/g' "$file"
    sed -i 's/<\/Ionicons>/<\/AppIcon>/g' "$file"
done

echo ""
echo "=== TypeScript check ==="
npx tsc --noEmit 2>&1 | head -20
