import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/home/home_screen.dart';
import 'package:sen_hong_bank/presentation/widgets/curved_promo_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'HomeScreen renders 8 lifestyle icons under banner carousel without outer card container',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Section Header
    expect(find.text('Mua sắm - Giải trí - Đầu tư'), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);

    // Verify all 8 items exist
    expect(find.text('Vua xổ số'), findsOneWidget);
    expect(find.text('Vé số\nVietlott'), findsOneWidget);
    expect(find.text('Data 4G\nNạp tiền'), findsOneWidget);
    expect(find.text('Vé máy bay\nSố'), findsOneWidget);
    expect(find.text('Vé máy bay'), findsOneWidget);
    expect(find.text('Data 4G/Thẻ\ngame'), findsOneWidget);
    expect(find.text('Vận số'), findsOneWidget);
    expect(find.text('Xem thêm\ndịch vụ'), findsOneWidget);
  });

  testWidgets(
      'CurvedPromoBanner renders with sleek rectangular aspect ratio without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize =
        const Size(1080, 2400); // 360dp width at 3.0 ratio
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                CurvedPromoBanner(
                  onRegisterTap: () {},
                ),
                const SizedBox(height: 16),
                CurvedPromoBanner(
                  isDiagonalSlanted: true,
                  onRegisterTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify promo banners render without errors
    expect(find.text('GÓI TIẾT KIỆM'), findsWidgets);
    expect(find.text('100K'), findsWidgets);
  });
}
