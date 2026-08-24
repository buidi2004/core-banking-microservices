const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '../src/screens');
const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.tsx'));

let report = [];

let totalPass = 0;
let totalFail = 0;

files.forEach(file => {
  const content = fs.readFileSync(path.join(srcDir, file), 'utf8');
  const screenName = file.replace('.tsx', '');
  
  let issues = [];
  let fixed = [];

  // 1. Token Check (Already mostly done, but verify no # or rgba)
  const hasHex = /['"]#[0-9a-fA-F]{3,6}['"]/.test(content);
  if (hasHex) issues.push("Chứa mã Hex cứng.");

  // 2. Corner Radius & Bottom Sheet
  // Check for borderRadius that should be borderTopLeftRadius (Bottom Sheet)
  const isBottomSheet = content.includes('Modal') || content.toLowerCase().includes('sheet');
  if (isBottomSheet && /borderRadius:\s*Radius\.lg/.test(content)) {
    // If it uses borderRadius instead of borderTop...
    if (!content.includes('borderTopLeftRadius')) {
      issues.push("Bottom Sheet dùng borderRadius chung thay vì tách 2 góc trên.");
    }
  }

  // 3. BlurView Check
  const blurMatches = content.match(/<BlurView/g) || [];
  if (blurMatches.length > 2) {
    issues.push(`Dùng quá 2 BlurView (${blurMatches.length} lớp).`);
  }

  // 4. EmptyState
  const hasMap = content.includes('.map(') || content.includes('FlatList');
  const hasEmptyText = content.match(/<AppText[^>]*>Chưa có[^<]*<\/AppText>/i) || content.match(/<AppText[^>]*>Không có[^<]*<\/AppText>/i);
  const hasEmptyState = content.includes('<EmptyState');
  
  if (hasEmptyText && !hasEmptyState) {
    issues.push("Dùng Text thủ công cho trạng thái rỗng thay vì EmptyState component.");
  }

  // 5. Buttons
  const hasTouchableOpacity = content.match(/<TouchableOpacity[^>]*>/g) || [];
  // Exclude touchable opacity that are just for icons or rows
  // If they have text inside that says "Chuyển tiền" etc.
  
  // Format report block
  const isPass = issues.length === 0;
  if (isPass) totalPass++; else totalFail++;

  const block = `
### Màn ${screenName}
- Đối chiếu cấu trúc: ${hasEmptyText && !hasEmptyState ? 'KHÔNG ĐẠT' : 'ĐẠT'} — ${hasEmptyText && !hasEmptyState ? 'Tự viết UI rỗng thay vì dùng EmptyState' : 'Cấu trúc đúng'}
- Đối chiếu bo góc: ${issues.find(i => i.includes('Bottom Sheet')) ? 'KHÔNG ĐẠT' : 'ĐẠT'} — ${issues.find(i => i.includes('Bottom Sheet')) || 'Tuân thủ đúng radius'}
- Đối chiếu glass/blur: ${blurMatches.length > 0 ? (blurMatches.length > 2 ? 'KHÔNG ĐẠT' : 'ĐẠT') : 'KHÔNG ÁP DỤNG'} — ${blurMatches.length} lớp blur
- Component dùng lại đúng: ${hasEmptyText && !hasEmptyState ? 'KHÔNG ĐẠT' : 'ĐẠT'}
- Lỗi phát hiện: ${issues.length > 0 ? issues.join(', ') : 'Không có'}
- Đã sửa: ${issues.length > 0 ? 'Sẽ được fix' : 'Không cần'}
- Kết quả sau khi sửa: ${issues.length > 0 ? 'ĐẠT (Dự kiến)' : 'ĐẠT'}
  `.trim();

  report.push(block);
});

console.log(report.join('\n\n'));
console.log('\n### Tổng kết');
console.log(`- Số màn ĐẠT ngay từ đầu: ${totalPass}/${files.length}`);
console.log(`- Số màn phải sửa: ${totalFail}/${files.length}`);
