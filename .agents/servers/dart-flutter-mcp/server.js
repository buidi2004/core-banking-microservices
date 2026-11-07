#!/usr/bin/env node
/**
 * Dart & Flutter MCP Server for Antigravity, Cursor, Claude Desktop, and VS Code.
 * Model Context Protocol (MCP) stdio server providing:
 *   - Static analysis via `flutter analyze` / `dart analyze`
 *   - Test runner via `flutter test`
 *   - Toolchain diagnostics via `flutter doctor`
 *   - Dependency resolution via `flutter pub get`
 *   - Flutter Anti-Slop Widget Inspector (Bottom Bar padding, Liquid Glass, Tabular figures)
 *   - Memory Leak & State Management Audit (Controller disposal, StreamSubscription leaks)
 */

const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const WORKSPACE_ROOT = path.resolve(__dirname, '../../..');
const MOBILE_DIR = path.join(WORKSPACE_ROOT, 'mobile');
const EKYC_SDK_DIR = path.join(WORKSPACE_ROOT, 'packages/ekyc_sdk');

// Tìm đường dẫn flutter / dart
let FLUTTER_BIN = 'flutter';
if (fs.existsSync('/home/buidi/snap/flutter/common/flutter/bin/flutter')) {
  FLUTTER_BIN = '/home/buidi/snap/flutter/common/flutter/bin/flutter';
}
const DART_BIN = path.join(path.dirname(FLUTTER_BIN), 'dart');

// Định nghĩa các công cụ MCP
const TOOLS = [
  {
    name: 'dart_analyze',
    description: 'Chạy phân tích tĩnh mã nguồn Dart/Flutter bằng `flutter analyze`, phát hiện lỗi cú pháp, cảnh báo linter, quy tắc type safety và deprecated APIs.',
    inputSchema: {
      type: 'object',
      properties: {
        target: {
          type: 'string',
          description: 'Thư mục hoặc file cần phân tích: "mobile", "packages/ekyc_sdk", hoặc đường dẫn tương đối (mặc định: "mobile").',
          default: 'mobile'
        }
      }
    }
  },
  {
    name: 'flutter_test',
    description: 'Chạy bộ kiểm thử tự động (Unit test, Widget test) bằng `flutter test` và trả về kết quả chi tiết từng test case.',
    inputSchema: {
      type: 'object',
      properties: {
        testPath: {
          type: 'string',
          description: 'Đường dẫn file test hoặc thư mục test (ví dụ: "test/nfc_reader_screen_test.dart", "packages/ekyc_sdk/test"). Mặc định chạy toàn bộ test của mobile.'
        }
      }
    }
  },
  {
    name: 'flutter_doctor',
    description: 'Kiểm tra trạng thái Flutter SDK, Dart SDK, Android Toolchain, connected devices và các công cụ phát triển liên quan.',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'flutter_pub_get',
    description: 'Cập nhật và tải dependencies trong file pubspec.yaml của module mobile hoặc ekyc_sdk.',
    inputSchema: {
      type: 'object',
      properties: {
        target: {
          type: 'string',
          description: 'Mục tiêu: "mobile" hoặc "packages/ekyc_sdk" (mặc định: "mobile").',
          default: 'mobile'
        }
      }
    }
  },
  {
    name: 'flutter_widget_inspector',
    description: 'Kiểm tra tuân thủ tiêu chuẩn giao diện Fintech & Anti-Slop Design (Liquid Glass, Bottom Bar 110dp clearance, Tabular Figures cho số dư tiền tệ, Haptic Feedback).',
    inputSchema: {
      type: 'object',
      properties: {
        filePath: {
          type: 'string',
          description: 'Đường dẫn file widget .dart cần kiểm tra (ví dụ: "mobile/lib/presentation/screens/profile_ekyc/nfc_reader_screen.dart").'
        }
      },
      required: ['filePath']
    }
  },
  {
    name: 'flutter_memory_leak_audit',
    description: 'Quét và phát hiện nguy cơ rò rỉ bộ nhớ (Memory Leak) trong mã nguồn Flutter: Quên dispose() TextEditingController, AnimationController, ScrollController hoặc StreamSubscription.',
    inputSchema: {
      type: 'object',
      properties: {
        directory: {
          type: 'string',
          description: 'Thư mục cần quét (mặc định: "mobile/lib").',
          default: 'mobile/lib'
        }
      }
    }
  }
];

// Hàm chạy tiến trình shell có giới hạn thời gian
function runProcess(cmd, args, cwd, timeoutMs = 60000) {
  return new Promise((resolve) => {
    try {
      const child = spawn(cmd, args, { cwd, shell: true });
      let stdout = '';
      let stderr = '';

      child.stdout.on('data', (d) => { stdout += d.toString(); });
      child.stderr.on('data', (d) => { stderr += d.toString(); });

      const timer = setTimeout(() => {
        child.kill();
        resolve({ code: 124, output: stdout + '\n' + stderr + '\n[TIMEOUT after ' + timeoutMs + 'ms]' });
      }, timeoutMs);

      child.on('close', (code) => {
        clearTimeout(timer);
        resolve({ code, output: stdout || stderr || 'No output' });
      });

      child.on('error', (err) => {
        clearTimeout(timer);
        resolve({ code: 1, output: 'Spawn error: ' + err.message });
      });
    } catch (e) {
      resolve({ code: 1, output: 'Execution error: ' + e.message });
    }
  });
}

// Xử lý thực thi từng Tool
async function handleToolCall(name, args) {
  switch (name) {
    case 'dart_analyze': {
      const target = args?.target || 'mobile';
      let cwd = MOBILE_DIR;
      if (target.includes('ekyc_sdk')) {
        cwd = EKYC_SDK_DIR;
      }
      const res = await runProcess(FLUTTER_BIN, ['analyze', '--no-pub'], cwd, 45000);
      return res.output;
    }

    case 'flutter_test': {
      let testPath = args?.testPath || '';
      let cwd = MOBILE_DIR;
      if (testPath.startsWith('packages/ekyc_sdk')) {
        cwd = EKYC_SDK_DIR;
        testPath = testPath.replace('packages/ekyc_sdk/', '');
      }
      const testArgs = testPath ? ['test', testPath] : ['test'];
      const res = await runProcess(FLUTTER_BIN, testArgs, cwd, 60000);
      return res.output;
    }

    case 'flutter_doctor': {
      const res = await runProcess(FLUTTER_BIN, ['doctor', '-v'], WORKSPACE_ROOT, 30000);
      return res.output;
    }

    case 'flutter_pub_get': {
      const target = args?.target || 'mobile';
      const cwd = target.includes('ekyc_sdk') ? EKYC_SDK_DIR : MOBILE_DIR;
      const res = await runProcess(FLUTTER_BIN, ['pub', 'get'], cwd, 30000);
      return res.output;
    }

    case 'flutter_widget_inspector': {
      const filePath = path.resolve(WORKSPACE_ROOT, args.filePath);
      if (!fs.existsSync(filePath)) {
        return `File không tồn tại: ${args.filePath}`;
      }
      const content = fs.readFileSync(filePath, 'utf-8');
      const issues = [];
      const compliments = [];

      // 1. Kiểm tra Tabular figures cho tiền tệ
      if (content.includes('balance') || content.includes('amount') || content.includes('VND') || content.includes('price')) {
        if (content.includes('FontFeature.tabularFigures()')) {
          compliments.push('✓ Đã bật FontFeature.tabularFigures() cho số liệu tài chính.');
        } else {
          issues.push('⚠️ Thiếu FontFeature.tabularFigures(): Khi hiển thị số dư hoặc tiền tệ, chữ số có thể bị giật dòng.');
        }
      }

      // 2. Kiểm tra đệm đáy Bottom Bar
      if (content.includes('CustomScrollView') || content.includes('ListView')) {
        if (content.includes('110') || content.includes('120') || content.includes('kBottomNavigationBarHeight')) {
          compliments.push('✓ Đã có khoảng đệm đáy >= 110dp cho IOSLiquidGlassTabBar.');
        } else {
          issues.push('⚠️ Thiếu đệm đáy Bottom Bar: Cần SizedBox(height: 110) ở cuối ListView/CustomScrollView để không bị che bởi Bottom Bar.');
        }
      }

      // 3. Kiểm tra Haptic Feedback
      if (content.includes('onTap') || content.includes('GestureDetector') || content.includes('InkWell')) {
        if (content.includes('HapticFeedback')) {
          compliments.push('✓ Đã tích hợp rung phản hồi xúc giác (HapticFeedback).');
        } else {
          issues.push('ℹ️ Gợi ý: Bổ sung HapticFeedback.selectionClick() khi người dùng chạm nút thanh toán hoặc thẻ.');
        }
      }

      let report = `### BÁO CÁO WIDGET INSPECTION: ${path.basename(filePath)}\n\n`;
      if (compliments.length > 0) {
        report += `**Điểm chuẩn đạt được:**\n${compliments.join('\n')}\n\n`;
      }
      if (issues.length > 0) {
        report += `**Vấn đề cần lưu ý:**\n${issues.join('\n')}\n`;
      } else {
        report += `✨ Không phát hiện vi phạm Anti-Slop design. Mã nguồn đạt chuẩn Fintech Tier-1!`;
      }
      return report;
    }

    case 'flutter_memory_leak_audit': {
      const scanDir = path.resolve(WORKSPACE_ROOT, args?.directory || 'mobile/lib');
      if (!fs.existsSync(scanDir)) {
        return `Thư mục không tồn tại: ${scanDir}`;
      }

      function getDartFiles(dir) {
        let results = [];
        const list = fs.readdirSync(dir);
        for (const file of list) {
          const fullPath = path.join(dir, file);
          const stat = fs.statSync(fullPath);
          if (stat && stat.isDirectory()) {
            results = results.concat(getDartFiles(fullPath));
          } else if (file.endsWith('.dart')) {
            results.push(fullPath);
          }
        }
        return results;
      }

      const files = getDartFiles(scanDir);
      const warnings = [];

      for (const file of files) {
        const text = fs.readFileSync(file, 'utf-8');
        // Kiểm tra State class có controller mà không có dispose
        if (text.includes('extends State<') || text.includes('StateNotifier')) {
          const hasController = /late\s+(final\s+)?(TextEditingController|AnimationController|ScrollController|PageController)\b/.test(text)
            || /(TextEditingController|AnimationController|ScrollController)\s+[a-zA-Z0-9_]+\s*=/.test(text);
          const hasDispose = /void\s+dispose\s*\(\s*\)/.test(text);

          if (hasController && !hasDispose) {
            const rel = path.relative(WORKSPACE_ROOT, file);
            warnings.push(`- **${rel}**: Khởi tạo Controller nhưng không tìm thấy phương thức \`dispose()\` override!`);
          }

          // Kiểm tra StreamSubscription
          if (text.includes('StreamSubscription') && !text.includes('.cancel()')) {
            const rel = path.relative(WORKSPACE_ROOT, file);
            warnings.push(`- **${rel}**: Khởi tạo StreamSubscription nhưng không thấy lệnh \`.cancel()\` giải phóng.`);
          }
        }
      }

      if (warnings.length === 0) {
        return `✅ Đã quét ${files.length} file Dart trong \`${args?.directory || 'mobile/lib'}\`: Không phát hiện Controller/Subscription bị bỏ quên dispose()!`;
      } else {
        return `⚠️ Phát hiện ${warnings.length} nguy cơ rò rỉ bộ nhớ (Memory Leak):\n\n${warnings.join('\n')}`;
      }
    }

    default:
      throw new Error(`Công cụ không hỗ trợ: ${name}`);
  }
}

// Lắng nghe JSON-RPC 2.0 qua stdio
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', async (line) => {
  line = line.trim();
  if (!line) return;

  try {
    const req = JSON.parse(line);
    const { id, method, params } = req;

    if (method === 'initialize') {
      const resp = {
        jsonrpc: '2.0',
        id,
        result: {
          protocolVersion: '2024-11-05',
          capabilities: {
            tools: {}
          },
          serverInfo: {
            name: 'dart-flutter-mcp',
            version: '1.0.0'
          }
        }
      };
      process.stdout.write(JSON.stringify(resp) + '\n');
    } else if (method === 'notifications/initialized') {
      // Client báo đã khởi tạo xong, không cần trả lời
    } else if (method === 'tools/list') {
      const resp = {
        jsonrpc: '2.0',
        id,
        result: {
          tools: TOOLS
        }
      };
      process.stdout.write(JSON.stringify(resp) + '\n');
    } else if (method === 'tools/call') {
      const toolName = params?.name;
      const toolArgs = params?.arguments || {};
      try {
        const textResult = await handleToolCall(toolName, toolArgs);
        const resp = {
          jsonrpc: '2.0',
          id,
          result: {
            content: [
              {
                type: 'text',
                text: typeof textResult === 'string' ? textResult : JSON.stringify(textResult, null, 2)
              }
            ]
          }
        };
        process.stdout.write(JSON.stringify(resp) + '\n');
      } catch (err) {
        const resp = {
          jsonrpc: '2.0',
          id,
          result: {
            content: [
              {
                type: 'text',
                text: `[LỖI THỰC THI TOOL ${toolName}]: ${err.message}`
              }
            ],
            isError: true
          }
        };
        process.stdout.write(JSON.stringify(resp) + '\n');
      }
    } else if (method === 'ping') {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result: {} }) + '\n');
    } else {
      // Method khác
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id, result: {} }) + '\n');
    }
  } catch (e) {
    // Không parse được json, bỏ qua
  }
});

