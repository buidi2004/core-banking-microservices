import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/beneficiaries_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/choose_recipient_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/confirm_transfer_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/enter_amount_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/request_transfer_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/transfer_result_screen.dart';

import 'support/contrast_audit.dart';

/// ---------------------------------------------------------------------------
/// AUDIT-TP-CONTRAST-001
/// Kiểm tra tương phản chữ (WCAG AA) + icon (WCAG 1.4.11) cho toàn bộ luồng
/// CHUYỂN TIỀN NỘI BỘ ("Ví tới Ví (Nội bộ)") của app SenBank Mobile.
///
/// Nền ứng dụng là ảnh SÁNG (`glass_background_pattern.png`, trung bình #E0E2E1)
/// và theme là `lightTheme` → mọi chữ sáng trên kính là "phản quan".
/// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> audit(
    WidgetTester tester,
    Widget screen,
    String name,
  ) async {
    await tester.pumpWidget(auditHarness(screen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final textFindings = collectTextFindings(tester);
    final iconFindings = collectIconFindings(tester);
    // Bỏ qua timer mạng của Dio để test không bị "pending timer".
    await tester.pump(const Duration(seconds: 1));
    printContrastReport(name, textFindings);
    printIconReport(name, iconFindings);
    expect(countReversed(textFindings), 0,
        reason: '$name không được có chữ bị phản quan');
    expect(countIconReversed(iconFindings), 0,
        reason: '$name không được có icon bị phản quan');
  }

  group('AUDIT-TP-CONTRAST-001 · Luồng chuyển tiền nội bộ', () {
    testWidgets('M1 · ChooseRecipientScreen (/transfer)', (tester) async {
      await audit(tester, const ChooseRecipientScreen(), 'M1 ChooseRecipientScreen');
    });

    testWidgets('M2 · EnterAmountScreen (/transfer/amount)', (tester) async {
      await audit(
        tester,
        const EnterAmountScreen(
          recipient: 'NGUYEN VAN A',
          phoneNumber: '0901234567',
          walletId: 'wallet-1',
        ),
        'M2 EnterAmountScreen',
      );
    });

    testWidgets('M3 · ConfirmTransferScreen (/transfer/confirm)',
        (tester) async {
      await audit(
        tester,
        const ConfirmTransferScreen(
          recipient: 'NGUYEN VAN A',
          phoneNumber: '0901234567',
          walletId: 'wallet-1',
          amount: 500000,
          note: 'Chuyen tien',
        ),
        'M3 ConfirmTransferScreen',
      );
    });

    testWidgets('M4 · TransferResultScreen (/transfer/result)',
        (tester) async {
      await audit(
        tester,
        const TransferResultScreen(
          recipient: 'NGUYEN VAN A',
          phoneNumber: '0901234567',
          amount: 500000,
          note: 'Chuyen tien',
          transactionId: 'TX-001',
        ),
        'M4 TransferResultScreen',
      );
    });

    testWidgets('M5 · BeneficiariesScreen (/beneficiaries)', (tester) async {
      await audit(tester, const BeneficiariesScreen(), 'M5 BeneficiariesScreen');
    });

    testWidgets('M6 · RequestTransferScreen (/transfer/request)',
        (tester) async {
      await audit(tester, const RequestTransferScreen(), 'M6 RequestTransferScreen');
    });

    testWidgets('M3b · Bàn phím PIN (CustomPinNumpad) hiển thị sau khi bấm "Xác nhận & Ký mã PIN"',
        (tester) async {
      await tester.pumpWidget(
        auditHarness(
          const ConfirmTransferScreen(
            recipient: 'NGUYEN VAN A',
            phoneNumber: '0901234567',
            walletId: 'wallet-1',
            amount: 500000,
            note: 'Chuyen tien',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final pinCta = find.text('Xác nhận & Ký mã PIN');
      expect(pinCta, findsOneWidget);
      await tester.ensureVisible(pinCta);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(pinCta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nhập mã PIN 6 số để duyệt chuyển tiền'), findsOneWidget);

      final textFindings = collectTextFindings(tester);
      final iconFindings = collectIconFindings(tester);
      printContrastReport('M3b CustomPinNumpad', textFindings);
      printIconReport('M3b CustomPinNumpad', iconFindings);
      expect(countReversed(textFindings), 0,
          reason: 'Bàn phím PIN không được có chữ bị phản quan');
      expect(countIconReversed(iconFindings), 0,
          reason: 'Bàn phím PIN không được có icon bị phản quan');
    });
  });
}
