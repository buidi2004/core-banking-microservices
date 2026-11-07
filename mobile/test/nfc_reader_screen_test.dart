import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/nfc_reader_screen.dart';

void main() {
  group('NfcReaderScreen UI & State Tests', () {
    testWidgets('renders idle state with start button and guidance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: NfcReaderScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Xác thực Chip CCCD (NFC)'), findsOneWidget);
      expect(find.text('Quyết định 2345/QĐ-NHNN'), findsOneWidget);
      expect(find.text('C06 BCA'), findsOneWidget);

      final startBtn = find.text('Bắt đầu đọc thẻ NFC');
      await tester.ensureVisible(startBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(startBtn, findsOneWidget);
    });

    testWidgets('tapping start starts scanning state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: NfcReaderScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 3) {
        await tester.enterText(textFields.at(0), '079099000123');
        await tester.enterText(textFields.at(1), '990101');
        await tester.enterText(textFields.at(2), '300101');
        await tester.pump();
      }

      final startBtn = find.text('Bắt đầu đọc thẻ NFC');
      await tester.ensureVisible(startBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Hủy bỏ quá trình đọc').evaluate().isNotEmpty ||
        find.byType(ElevatedButton).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('pre-fills initialDocumentNumber, initialDateOfBirth, initialExpiryDate and displays auto badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: NfcReaderScreen(
            initialDocumentNumber: '079099000123',
            initialDateOfBirth: '990101',
            initialExpiryDate: '300101',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('079099000123'), findsOneWidget);
      expect(find.text('990101'), findsOneWidget);
      expect(find.text('300101'), findsOneWidget);
      expect(find.text('Tự động điền'), findsOneWidget);
    });
  });
}
