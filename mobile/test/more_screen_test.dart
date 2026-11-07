import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/presentation/screens/more/more_screen.dart';

void main() {
  group('MoreScreen Minimalist Redesign Tests', () {
    testWidgets('renders minimalist sections and neutral grey icons properly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề các nhóm mới chuẩn Typography bài phân tích
      expect(find.text('Tiện ích trọng tâm'), findsOneWidget);
      expect(find.text('Tài chính & Nguồn tiền'), findsOneWidget);
      expect(find.text('Tiện ích đời sống'), findsOneWidget);
      expect(find.text('Cài đặt chung'), findsOneWidget);
      expect(find.text('Hỗ trợ & Hợp tác'), findsOneWidget);

      // Kiểm tra các nhãn chức năng
      expect(find.text('Quản lý thẻ Sen Hồng (Visa / Napas)'), findsOneWidget);
      expect(find.text('Tiết kiệm Sen Lộc Phát Online'), findsOneWidget);

      // Kiểm tra Icon nét đơn Lucide xám chì (#616161)
      final iconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == LucideIcons.creditCard &&
            widget.color == const Color(0xFF616161),
      );
      expect(iconFinder, findsWidgets);

      // Kiểm tra mũi tên điều hướng mảnh (#9E9E9E)
      final chevronFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == LucideIcons.chevronRight &&
            widget.color == const Color(0xFF9E9E9E),
      );
      expect(chevronFinder, findsWidgets);
    });
  });
}
