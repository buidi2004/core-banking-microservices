import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/all_services_screen.dart';

void main() {
  group('AllServicesScreen Widget Tests', () {
    testWidgets('renders all services headers and minimalist icons properly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AllServicesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề chính
      expect(find.text('Tất Cả Dịch Vụ'), findsOneWidget);

      // Kiểm tra các nhóm dịch vụ
      expect(find.text('Mua sắm - Giải trí - Đầu tư'), findsOneWidget);
      expect(find.text('Tài chính & Thẻ Ngân hàng'), findsOneWidget);

      // Kiểm tra các dịch vụ hiển thị
      expect(find.text('Vua Xổ Số'), findsOneWidget);
      expect(find.text('XSMB, XSMN, XSMT trực tiếp'), findsOneWidget);
      expect(find.text('Chuyển tiền Napas 24/7'), findsOneWidget);

      // Kiểm tra Lucide Icons hiển thị
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);
      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('filters services correctly when typing in search bar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AllServicesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Nhập từ khóa tìm kiếm
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'tiền điện');
      await tester.pumpAndSettle();

      // Chỉ hiển thị 'Tiền điện EVN'
      expect(find.text('Tiền điện EVN'), findsOneWidget);
      expect(find.text('Vua Xổ Số'), findsNothing);

      // Nút xóa từ khóa (circleX) xuất hiện
      expect(find.byIcon(LucideIcons.circleX), findsOneWidget);

      // Nhấn nút xóa
      await tester.tap(find.byIcon(LucideIcons.circleX));
      await tester.pumpAndSettle();

      // Danh sách phục hồi lại đầy đủ
      expect(find.text('Vua Xổ Số'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleX), findsNothing);
    });
  });
}
