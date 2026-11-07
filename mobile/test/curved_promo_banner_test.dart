import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:sen_hong_bank/presentation/widgets/curved_promo_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurvedPromoBanner (nội dung thật từ Backend /campaigns)', () {
    testWidgets('ẩn banner khi chưa tải được campaign (không còn quảng cáo giả)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurvedPromoBanner(),
          ),
        ),
      );
      // Cho phép future lỗi mạng hoàn tất (không có backend trong môi trường test)
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Dữ liệu mock đã bị loại bỏ: khi API không khả dụng, banner ẩn đi
      // thay vì hiển thị quảng cáo thương hiệu hardcode (ZARA/NIKE/GUCCI...).
      expect(find.byType(FlutterCarousel), findsNothing);
      expect(find.textContaining('ZARA'), findsNothing);
      expect(find.textContaining('NIKE'), findsNothing);
      expect(find.textContaining('GUCCI'), findsNothing);
    });

    testWidgets('biến thể diagonal slanted cũng ẩn khi không có dữ liệu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CurvedPromoBanner(isDiagonalSlanted: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CurvedPromoBanner), findsOneWidget);
      expect(find.byType(FlutterCarousel), findsNothing);
    });
  });
}
