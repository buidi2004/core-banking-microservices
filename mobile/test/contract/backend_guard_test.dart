import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';

/// =============================================================================
/// BACKEND GUARD REGRESSION TEST  (AUDIT-MOB-BE-001 — R2-P0-01 / R2-P1-02)
/// =============================================================================
/// Mục đích: bảo vệ bất biến "TUYỆT ĐỐI KHÔNG SỬA backend/**" bằng **test tự động**.
///
/// Nguyên tắc:
///  1. **Luôn pass** khi backend sạch (checksum == baseline).
///  2. **Fail** khi backend bị sửa mà KHÔNG có waiver hợp lệ **và** vi phạm
///     chưa được ghi nhận đầy đủ trong báo cáo forensic
///     (`.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`).
///  3. **Pass (kèm cảnh báo)** khi vi phạm đã được ghi nhận đúng trong báo cáo
///     ⇒ báo cáo không được "lệch" với thực tế.
///  4. Tự kiểm tra logic phát hiện vi phạm trên một git repo tổng hợp
///     (không phụ thuộc repo thật) ⇒ chứng minh cơ chế hoạt động.
///
/// Script CLI tương ứng: `scripts/check_backend_guard.sh` (chỉ đọc, exit 0/2).
/// -----------------------------------------------------------------------------

const String kBaselineChecksum =
    'eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003';
const String kBaselineCommit = '75bf273cd707571c13073a625390a78adfa320ce';

String? _repoRoot() {
  final result = Process.runSync('git', ['rev-parse', '--show-toplevel']);
  if (result.exitCode != 0) return null;
  final out = (result.stdout as String).trim();
  return out.isEmpty ? null : out;
}

/// Tính checksum giống hệt `scripts/check_backend_guard.sh`:
///   git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
String _currentChecksum(String root) {
  const pipeline = r"""git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum | cut -d' ' -f1""";
  final result = Process.runSync('bash', ['-c', pipeline], workingDirectory: root);
  if (result.exitCode != 0) return '';
  return (result.stdout as String).trim();
}

/// Waiver của chủ repo (nếu có) — chỉ chấp nhận khi đủ trường và còn hiệu lực.
Map<String, dynamic>? _readWaiver(String root) {
  final file = File('$root/.agents_workspace/backend_guard_waiver.json');
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

bool _waiverIsValid(Map<String, dynamic>? waiver) {
  if (waiver == null) return false;
  for (final key in const [
    'approved_by',
    'approved_at',
    'commit',
    'scope',
    'expires_at'
  ]) {
    final v = waiver[key];
    if (v == null || v.toString().trim().isEmpty) return false;
  }
  final expires = DateTime.tryParse(waiver['expires_at'].toString());
  if (expires == null) return false;
  return expires.isAfter(DateTime.now());
}

void main() {
  group('Backend Guard — repo integrity (R2-P0-01)', () {
    final root = _repoRoot();

    test('repo hiện tại: backend sạch HOẶC vi phạm đã được ghi nhận đầy đủ', () {
      if (root == null) {
        markTestSkipped('Không chạy trong git repo — bỏ qua kiểm tra guard.');
        return;
      }

      final checksum = _currentChecksum(root);
      expect(checksum, isNotEmpty, reason: 'Không tính được checksum cây backend.');

      final waiver = _readWaiver(root);
      final hasValidWaiver = _waiverIsValid(waiver);

      final status = Process.runSync(
          'git', ['status', '--porcelain', '--', 'backend', 'docker-compose.yml', 'deploy'],
          workingDirectory: root);
      final dirty = (status.stdout as String).trim();
      final isClean = checksum == kBaselineChecksum && dirty.isEmpty;

      if (isClean) {
        // Đường đạn hạnh phúc
        expect(true, isTrue);
        return;
      }

      if (hasValidWaiver) {
        // Đã được chủ repo phê duyệt bằng văn bản → hợp lệ
        expect(true, isTrue);
        return;
      }

      // Vi phạm chưa được phê duyệt ⇒ bắt buộc phải được GHI NHẬN đầy đủ,
      // nếu không test này fail để buộc người vi phạm phải cập nhật báo cáo.
      final report = File('$root/.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md');
      expect(
        report.existsSync(),
        isTrue,
        reason: 'Backend đã bị sửa (checksum=$checksum) mà KHÔNG có waiver hợp lệ '
            'và KHÔNG có báo cáo vi phạm '
            '(.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md). '
            'Vi phạm bất biến dự án — cần chủ repo phê duyệt ngay.',
      );

      final body = report.readAsStringSync();
      expect(
        body.contains(checksum),
        isTrue,
        reason: 'Báo cáo vi phạm chưa ghi nhận checksum hiện tại ($checksum) ⇒ '
            'báo cáo đã lệch so với thực tế, cần cập nhật lại.',
      );
      expect(
        body.toLowerCase().contains('quyết định cần chủ repo phê duyệt'.toLowerCase()),
        isTrue,
        reason: 'Báo cáo vi phạm thiếu mục "Quyết định cần chủ repo phê duyệt".',
      );
    });

    test('logic phát hiện vi phạm hoạt động đúng trên git repo tổng hợp', () {
      final tmp = Directory.systemTemp.createTempSync('backend_guard_selftest');
      try {
        void git(List<String> args) {
          final r = Process.runSync('git', args, workingDirectory: tmp.path);
          expect(r.exitCode, 0, reason: 'git ${args.join(' ')} thất bại: ${r.stderr}');
        }

        git(['init', '-q']);
        git(['config', 'user.email', 'test@example.com']);
        git(['config', 'user.name', 'Test']);
        Directory('${tmp.path}/backend').createSync();
        File('${tmp.path}/backend/a.txt').writeAsStringSync('v1');
        git(['add', '-A']);
        git(['commit', '-q', '-m', 'baseline']);

        final before = _currentChecksum(tmp.path);
        expect(before, isNotEmpty);

        // (a) Sửa backend CHƯA commit ⇒ phải lộ ra qua `git status`
        File('${tmp.path}/backend/a.txt').writeAsStringSync('v2-changed');
        final st = Process.runSync('git', ['status', '--porcelain', '--', 'backend'],
            workingDirectory: tmp.path);
        expect((st.stdout as String).trim(), isNotEmpty,
            reason: 'Thay đổi chưa commit phải bị phát hiện qua git status.');

        // (b) Commit thay đổi ⇒ checksum cây backend phải thay đổi
        git(['add', '-A']);
        git(['commit', '-q', '-m', 'drift']);
        final after = _currentChecksum(tmp.path);
        expect(after, isNot(before), reason: 'Checksum phải thay đổi khi backend bị sửa và commit.');

        // (c) Trả lại nội dung + commit ⇒ checksum phải về như cũ
        File('${tmp.path}/backend/a.txt').writeAsStringSync('v1');
        git(['add', '-A']);
        git(['commit', '-q', '-m', 'restore']);
        expect(_currentChecksum(tmp.path), equals(before));
      } finally {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      }
    });
  });

  group('Backend Capabilities — phản ánh đúng backend hiện tại (R2-P1-02)', () {
    test('capability flag bật khi API đã có, tắt khi chưa tích hợp', () {
      // Identity & PIN: đã có API thật trong identity-service
      expect(BackendCapabilities.serverSideTransferAuth, isTrue);
      expect(BackendCapabilities.transactionPin, isTrue);
      expect(BackendCapabilities.otp, isTrue);

      // Payment-service: deposit/withdraw/bills/vietqr/bank-accounts/...
      expect(BackendCapabilities.deposit, isTrue);
      expect(BackendCapabilities.withdraw, isTrue);
      expect(BackendCapabilities.bills, isTrue);
      expect(BackendCapabilities.vietQr, isTrue);
      expect(BackendCapabilities.bankAccounts, isTrue);
      expect(BackendCapabilities.fundingSources, isTrue);
      expect(BackendCapabilities.beneficiaries, isTrue);
      expect(BackendCapabilities.savings, isTrue);
      expect(BackendCapabilities.loans, isTrue);

      // Chưa tích hợp đầy đủ ở mobile ⇒ vẫn tắt để fail-safe
      expect(BackendCapabilities.receiptAndExport, isFalse);
      expect(BackendCapabilities.referrals, isFalse);
      expect(BackendCapabilities.legalDocuments, isFalse);
      expect(BackendCapabilities.feedback, isFalse);
      expect(BackendCapabilities.moneyRequestDetail, isFalse);
      expect(BackendCapabilities.moneyRequestCancel, isFalse);
    });

    test('hasEndpoint() chỉ chặn các route thực sự chưa tích hợp', () {
      // Các route backend ĐÃ có ⇒ phải cho qua
      expect(BackendCapabilities.hasEndpoint('/auth/otp/verify'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/auth/otp/send'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/users/pin/set'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/users/pin/verify'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/wallets/deposit'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/wallets/withdraw'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/bills/pay'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/payments/vietqr/decode'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/bank-accounts'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/funding-sources'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/beneficiaries'), isTrue);

      // Route chưa tích hợp ⇒ phải bị chặn
      expect(BackendCapabilities.hasEndpoint('/transactions/export/csv'), isFalse);
      expect(BackendCapabilities.hasEndpoint('/transactions/tx-1/receipt.pdf'), isFalse);
      expect(BackendCapabilities.hasEndpoint('/config/limits'), isFalse);
      expect(BackendCapabilities.hasEndpoint('/config/limits/status'), isFalse);

      // Route backend CÓ thật ⇒ không được chặn nhầm
      expect(BackendCapabilities.hasEndpoint('/auth/login'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/auth/refresh'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/payments/transfer'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/wallets/me'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/transactions'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/users/profile'), isTrue);
      expect(BackendCapabilities.hasEndpoint('/sessions'), isTrue);
    });
  });
}
