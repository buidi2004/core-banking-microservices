import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/presentation/screens/bills/bill_payment_screen.dart';

void main() {
  group('BillPaymentScreen Minimalist Redesign Tests', () {
    testWidgets('renders minimalist bill screen with neutral grey Lucide icons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: BillPaymentScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra tiêu đề trang
      expect(find.text('Thanh Toán Hóa Đơn'), findsOneWidget);

      // Kiểm tra danh bạ hóa đơn đã lưu
      expect(find.text('Danh bạ hóa đơn của tôi'), findsOneWidget);
      expect(find.text('Điện Nhà Riêng (Hà Nội)'), findsOneWidget);
      expect(find.text('Nước Sinh Hoạt Chung Cư'), findsOneWidget);

      // Kiểm tra icon nét đơn Lucide màu xám chì (#616161)
      final zapIconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == LucideIcons.zap &&
            widget.color == const Color(0xFF616161),
      );
      expect(zapIconFinder, findsWidgets);

      final dropletsIconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == LucideIcons.droplets &&
            widget.color == const Color(0xFF616161),
      );
      expect(dropletsIconFinder, findsWidgets);

      // Kiểm tra tab danh mục dịch vụ thanh toán
      expect(find.text('Danh mục dịch vụ thanh toán'), findsOneWidget);
      expect(find.text('Thiết yếu'), findsOneWidget);
      expect(find.text('Tài chính & Thẻ'), findsOneWidget);

      // Chuyển tab sang Tài chính & Thẻ
      await tester.tap(find.text('Tài chính & Thẻ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vay tiêu dùng'), findsOneWidget);
      expect(find.text('Thẻ tín dụng'), findsOneWidget);
    });
  });
}
