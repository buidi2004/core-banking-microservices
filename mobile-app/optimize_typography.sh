#!/bin/bash
# Optimize typography by replacing hardcoded fontSize with Typography tokens

cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Replacing hardcoded fontSize with Typography tokens ==="

# Process all screen files
for file in src/screens/*.tsx; do
    if grep -q 'fontSize:' "$file"; then
        echo "Processing: $file"
        
        # Replace common fontSize patterns
        # Large display (32px) -> display
        sed -i 's/fontSize: 32,/variant="display",/g' "$file"
        
        # Heading size (17-18px) -> heading  
        sed -i 's/fontSize: 1[78],/variant="heading",/g' "$file"
        
        # Body size (15-16px) -> body or bodyMedium
        sed -i 's/fontSize: 16,/variant="bodyMedium",/g' "$file"
        sed -i 's/fontSize: 15,/variant="body",/g' "$file"
        
        # Caption size (12-14px) -> caption
        sed -i 's/fontSize: 14,/variant="caption",/g' "$file"
        sed -i 's/fontSize: 13,/variant="caption",/g' "$file"
        sed -i 's/fontSize: 12,/variant="caption",/g' "$file"
        
        # Small size (11px) -> small
        sed -i 's/fontSize: 11,/variant="caption",/g' "$file"
    fi
done

# Process component files (these can keep their own styles)
for file in src/components/*.tsx; do
    if grep -q 'fontSize:' "$file"; then
        echo "Component has its own styles (OK): $(basename $file)"
    fi
done

echo ""
echo "=== Checking for remaining hardcoded fontFamily ==="
grep -rn 'fontFamily:' src --include='*.tsx' | grep -v 'theme.ts' | head -5

echo ""
echo "=== Running TypeScript check ==="
npx tsc --noEmit 2>&1 | head -20
