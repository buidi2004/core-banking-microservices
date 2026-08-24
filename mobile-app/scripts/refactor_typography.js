const fs = require('fs');
const path = require('path');

const SRC_DIRS = [
  path.join(__dirname, '../src/screens'),
  path.join(__dirname, '../src/components'),
];

function getRelativePath(from, to) {
  let rel = path.relative(path.dirname(from), to).replace(/\\/g, '/');
  if (!rel.startsWith('.')) {
    rel = './' + rel;
  }
  return rel.replace(/\.tsx$/, '');
}

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');

  // Skip if it doesn't use Text and has no fontSize
  if (!content.includes('<Text') && !content.includes('fontSize:') && !content.includes('fontFamily:')) {
    return;
  }

  // 1. Map styles to variants
  const lines = content.split('\n');
  const styleToVariant = {};
  let currentStyle = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const styleMatch = line.match(/^ {2}([a-zA-Z0-9_]+):\s*\{/);
    if (styleMatch) {
      currentStyle = styleMatch[1];
    }
    
    if (currentStyle) {
      // Check for Typography.xxx.fontSize
      const typoMatch = line.match(/fontSize:\s*Typography\.([a-zA-Z0-9_]+)\.fontSize/);
      if (typoMatch) {
        styleToVariant[currentStyle] = typoMatch[1];
      } else {
        // Fallback for hardcoded sizes
        const numMatch = line.match(/fontSize:\s*(\d+)/);
        if (numMatch) {
           const size = parseInt(numMatch[1], 10);
           if (size >= 32) styleToVariant[currentStyle] = 'display';
           else if (size >= 24) styleToVariant[currentStyle] = 'headingXl';
           else if (size >= 20) styleToVariant[currentStyle] = 'headingLg';
           else if (size >= 17) styleToVariant[currentStyle] = 'heading';
           else if (size === 16) styleToVariant[currentStyle] = 'bodyLg';
           else if (size === 15) styleToVariant[currentStyle] = 'body';
           else if (size === 14) styleToVariant[currentStyle] = 'caption';
           else if (size === 13) styleToVariant[currentStyle] = 'bodySm';
           else if (size <= 12) styleToVariant[currentStyle] = 'caption';
        }
      }
    }
    if (line.match(/^ {2}\},?/)) {
      currentStyle = null;
    }
  }

  // 2. Remove Text from react-native imports
  let hasTextImport = false;
  content = content.replace(/import\s+\{([^}]+)\}\s+from\s+['"]react-native['"];/g, (match, imports) => {
    if (imports.includes('Text')) {
      hasTextImport = true;
      let newImports = imports
        .split(',')
        .map(i => i.trim())
        .filter(i => i !== 'Text' && i !== '');
      if (newImports.length === 0) return '';
      return `import { ${newImports.join(', ')} } from 'react-native';`;
    }
    return match;
  });

  // Remove empty imports if any
  content = content.replace(/import\s+\{\s*\}\s+from\s+['"]react-native['"];\n?/g, '');

  // 3. Inject AppText import if we have <Text (or if we had Text import)
  if (content.match(/<Text\b/)) {
    const appTextPath = path.join(__dirname, '../src/components/typography/AppText.tsx');
    let relPath = getRelativePath(filePath, appTextPath);
    // Don't import itself
    if (filePath !== appTextPath) {
      if (!content.includes(`import { AppText }`)) {
        // Find last import
        const importRegex = /^import\s+.*from\s+['"].*['"];?$/gm;
        let lastMatch = null;
        let m;
        while ((m = importRegex.exec(content)) !== null) {
          lastMatch = m;
        }
        if (lastMatch) {
          const insertPos = lastMatch.index + lastMatch[0].length;
          content = content.slice(0, insertPos) + `\nimport { AppText } from '${relPath}';` + content.slice(insertPos);
        } else {
          content = `import { AppText } from '${relPath}';\n` + content;
        }
      }
    }
  }

  // 4. Inject variants into <Text> before replacing them
  content = content.replace(/<Text([^>]*)style=\{([^}]+)\}([^>]*)>/g, (match, before, styleContent, after) => {
     if (match.includes('variant=')) return match;
     let variant = null;
     for (const [styleName, variantName] of Object.entries(styleToVariant)) {
        if (styleContent.includes(`styles.${styleName}`)) {
           variant = variantName;
        }
     }
     if (variant) {
        return `<Text${before}variant="${variant}" style={${styleContent}}${after}>`;
     }
     return match;
  });

  // 5. Replace <Text and </Text>
  content = content.replace(/<Text\b/g, '<AppText');
  content = content.replace(/<\/Text>/g, '</AppText>');

  // 6. Strip fontSize, fontFamily, fontWeight from StyleSheet
  content = content.replace(/\bfontSize:\s*[^,}\n]+,?\s*/g, '');
  content = content.replace(/\bfontFamily:\s*[^,}\n]+,?\s*/g, '');
  content = content.replace(/\bfontWeight:\s*[^,}\n]+,?\s*/g, '');

  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`Processed ${filePath}`);
}

function walkDir(dir) {
  if (!fs.existsSync(dir)) return;
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      walkDir(fullPath);
    } else if (fullPath.endsWith('.tsx') || fullPath.endsWith('.ts')) {
      processFile(fullPath);
    }
  }
}

SRC_DIRS.forEach(walkDir);
console.log('Typography refactoring complete!');
