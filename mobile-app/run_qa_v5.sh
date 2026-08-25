#!/bin/bash
cd /home/wsk2/app-mono-di-va-khoa/mobile-app

echo "=== Running Grep Checks ==="
# Grep exact commands from user
grep -rn "borderRadius:\s*[0-9]" src/ --include="*.tsx" --include="*.ts" | grep -v "theme.ts" > grep_radius.txt || true
grep -rn "#[0-9A-Fa-f]\{3,6\}" src/ --include="*.tsx" --include="*.ts" | grep -v "theme.ts" > grep_color.txt || true
grep -rn "shadowColor" src/ --include="*.tsx" --include="*.ts" | grep -v "theme.ts" > grep_shadow.txt || true

echo "=== Setting up ESLint ==="
echo '{"extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended", "plugin:react/recommended"], "parser": "@typescript-eslint/parser", "plugins": ["@typescript-eslint", "react", "react-native"], "env": {"node": true, "react-native/react-native": true}, "rules": {"react/react-in-jsx-scope": "off"}}' > .eslintrc.json
# Install minimal eslint to avoid timeout
npm install --save-dev eslint typescript @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-native || true

echo "=== Running ESLint ==="
npx eslint src/screens > eslint_output.txt || true

echo "=== QA Run Complete ==="
