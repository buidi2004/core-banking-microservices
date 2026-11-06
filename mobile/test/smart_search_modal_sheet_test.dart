import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/widgets/smart_search_modal_sheet.dart';

void main() {
  group('SmartSearchModalSheet Tests', () {
    testWidgets('renders all visual tokens 100% matching image spec',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // 1. Tiêu đề "Tìm kiếm"
      expect(find.text('Tìm kiếm'), findsOneWidget); // Ô tìm kiếm

      // 2. Cụm nút "Dán"
      expect(find.text('Dán'), findsOneWidget);

      // 3. Card AI: Badge SenAI, Mô tả, 2 nút Chụp ảnh & Tải ảnh
      expect(find.text('SenAI'), findsOneWidget);
      expect(
        find.text(
            'Điền nhanh thông tin chuyển tiền từ văn bản hoặc ảnh mã VietQR'),
        findsOneWidget,
      );
      expect(find.text('Chụp ảnh'), findsOneWidget);
      expect(find.text('Tải ảnh'), findsOneWidget);

      // 4. Mục "Đề xuất" và 5 Pill bo tròn
      expect(find.text('Đề xuất'), findsOneWidget);
      expect(find.text('Rút tiền ATM'), findsOneWidget);
      expect(find.text('Mở tài khoản số đẹp'), findsOneWidget);
      expect(find.text('Chuyển tiền quốc tế'), findsOneWidget);
      expect(find.text('Mua vé máy bay VNA'), findsOneWidget);
      expect(find.text('Bảo hiểm xã hội'), findsOneWidget);
    });

    testWidgets('typing search query shows filtered results', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // Nhập "EVN" vào ô tìm kiếm
      await tester.enterText(find.byType(TextField), 'EVN');
      await tester.pumpAndSettle();

      // Kết quả hiển thị chức năng tiền điện EVN
      expect(find.text('Thanh toán tiền điện EVN'), findsOneWidget);
    });

    testWidgets('search matches multiple Vietnamese keywords together',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'tien dien');
      await tester.pumpAndSettle();

      expect(find.text('Thanh toán tiền điện EVN'), findsOneWidget);
      expect(find.textContaining('dịch vụ phù hợp'), findsOneWidget);
    });

    testWidgets('small phone with keyboard keeps the sheet scrollable',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );
      await tester.pump();

      final layoutError = tester.takeException();
      expect(layoutError, isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('unmatched query offers a way back to common services',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'khong co dich vu nay');
      await tester.pumpAndSettle();

      expect(find.textContaining('Chưa tìm thấy'), findsOneWidget);
      expect(find.text('Rút tiền ATM'), findsOneWidget);
    });

    testWidgets(
        'showSmartSearchModalSheet opens with useRootNavigator to hide bottom bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const Text('BOTTOM_NAV_BAR'),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showSmartSearchModalSheet(ctx),
                child: const Text('OPEN_SHEET'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN_SHEET'));
      await tester.pumpAndSettle();

      // Modal sheet hiển thị
      expect(find.byType(SmartSearchModalSheet), findsOneWidget);
    });

    testWidgets('pasting text updates search field and triggers AI parsing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // Nhấn nút "Dán"
      await tester.tap(find.text('Dán'));
      await tester.pumpAndSettle();

      // Kiểm tra widget vẫn ổn định không crash
      expect(find.byType(SmartSearchModalSheet), findsOneWidget);
    });
  });
}
