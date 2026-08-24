const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '../src');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.tsx') || file.endsWith('.ts')) {
        results.push(file);
      }
    }
  });
  return results;
}

const replacements = [
  { from: "'#FFF'", to: "Colors.white" },
  { from: '"#FFF"', to: "Colors.white" },
  { from: "'rgba(255,255,255,0.95)'", to: "Colors.glassSolid" },
  { from: '"rgba(255,255,255,0.95)"', to: "Colors.glassSolid" },
  { from: "'rgba(255,255,255,0.9)'", to: "Colors.glassOpaque" },
  { from: '"rgba(255,255,255,0.9)"', to: "Colors.glassOpaque" },
  { from: "'rgba(255,255,255,0.8)'", to: "Colors.glassHeavy" },
  { from: '"rgba(255,255,255,0.8)"', to: "Colors.glassHeavy" },
  { from: "'rgba(255,255,255,0.7)'", to: "Colors.glassStrong" },
  { from: '"rgba(255,255,255,0.7)"', to: "Colors.glassStrong" },
  { from: "'rgba(255,255,255,0.5)'", to: "Colors.glassMedium" },
  { from: '"rgba(255,255,255,0.5)"', to: "Colors.glassMedium" },
  { from: "'rgba(255,255,255,0.3)'", to: "Colors.glassLight" },
  { from: '"rgba(255,255,255,0.3)"', to: "Colors.glassLight" },
  { from: "'rgba(0,0,0,0.5)'", to: "Colors.overlayDark" },
  { from: '"rgba(0,0,0,0.5)"', to: "Colors.overlayDark" },
  { from: "opacity: 0.5", to: "opacity: Opacity.disabled" },
  { from: "opacity: 0.8", to: "opacity: Opacity.muted" }
];

const files = walk(srcDir);
files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let originalContent = content;
  let modified = false;

  replacements.forEach(({from, to}) => {
    // Only replace literal strings like 'rgba(...)' or opacity: ...
    if (content.includes(from)) {
      content = content.split(from).join(to);
      modified = true;
    }
  });

  if (modified) {
    // Check if we need to add Opacity import
    if (content.includes('Opacity.') && !content.includes('Opacity') && content.includes('../theme')) {
      // Need to add Opacity to theme imports
      content = content.replace(/(import\s+\{.*)Colors(.*\}\s+from\s+['"](?:\.\.\/)+theme['"])/, (match, p1, p2) => {
         if (!match.includes('Opacity')) return `${p1}Colors, Opacity${p2}`;
         return match;
      });
    }
    
    // We already have Colors in all these files because they are UI files.
    fs.writeFileSync(file, content, 'utf8');
    console.log(`Updated ${file}`);
  }
});
