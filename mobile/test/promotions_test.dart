import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/promotions/promotions_screen.dart';

void main() {
  testWidgets('PromotionsScreen renders banners, categories and promotions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PromotionsScreen(),
      ),
    );
    await tester.pump();

    // Verify AppBar title
    expect(find.text('Ưu Đãi & Quà Tặng'), findsOneWidget);

    // Verify Search bar hint
    expect(find.text('Tìm ưu đãi Highlands, Be, Shopee...'), findsOneWidget);

    // Verify SenPoint Club card
    expect(find.text('SenPoint Club'), findsOneWidget);

    // Verify Flash Sale section
    expect(find.text('Giờ Vàng Săn Deal'), findsOneWidget);

    // Verify categories
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Ẩm thực & Cafe'), findsWidgets);
    expect(find.text('Di chuyển & Xe'), findsWidgets);

    // Verify some brands exist
    expect(find.text('Highlands Coffee'), findsWidgets);
  });

  testWidgets('PromotionsScreen filters by category and search', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PromotionsScreen(),
      ),
    );
    await tester.pump();

    // Type search query
    await tester.enterText(find.byType(TextField).first, 'Highlands');
    await tester.pump();

    // Highlands should be found
    expect(find.text('Highlands Coffee'), findsWidgets);

    // Clear search
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    // Filter by Di chuyển & Xe
    await tester.tap(find.text('Di chuyển & Xe').first);
    await tester.pump();

    // BeCar should be present
    expect(find.text('BeCar & GrabCar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('PromotionsScreen switches between all tabs successfully', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PromotionsScreen(),
      ),
    );
    await tester.pump();

    // Tab 1: Trả Góp Nhà & Xe
    await tester.tap(find.text('Trả Góp Nhà & Xe'));
    await tester.pump();
    expect(find.text('Gói Vay Mua Nhà An Cư SenBank'), findsWidgets);

    // Tab 2: Sự Kiện
    await tester.tap(find.text('Sự Kiện'));
    await tester.pump();
    expect(find.text('Sự kiện đang diễn ra'), findsWidgets);

    // Tab 3: Voucher
    await tester.tap(find.text('Voucher'));
    await tester.pump();
    expect(find.text('Nhập Mã Ưu Đãi Độc Quyền'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  test('TicketCardClipper generates valid ticket path with notches', () {
    const clipper = TicketCardClipper(bottomBarHeight: 54.0, notchRadius: 9.0, cornerRadius: 18.0);
    final path = clipper.getClip(const Size(380, 200));
    expect(path.getBounds().isEmpty, isFalse);
    expect(clipper.shouldReclip(clipper), isFalse);
  });
}
