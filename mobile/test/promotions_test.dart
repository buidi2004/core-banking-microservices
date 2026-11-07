import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/promotions/promotions_screen.dart';

void main() {
  testWidgets('PromotionsScreen renders chrome, categories and honest empty states',
      (tester) async {
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

    // Verify Search bar hint (đã trung thực, không gợi ý thương hiệu mock)
    expect(find.text('Tìm ưu đãi, mã giảm giá...'), findsOneWidget);

    // Verify SenPoint Club card
    expect(find.text('SenPoint Club'), findsOneWidget);

    // Verify Flash Sale section
    expect(find.text('Giờ Vàng Săn Deal'), findsOneWidget);

    // Verify categories
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Ẩm thực & Cafe'), findsWidgets);
    expect(find.text('Di chuyển & Xe'), findsWidgets);

    // Nội dung mock đã bị loại bỏ: không còn thương hiệu/ưu đãi cứng
    expect(find.text('Highlands Coffee'), findsNothing);
    expect(find.text('BeCar & GrabCar'), findsNothing);

    // Danh sách ưu đãi trống (chưa gọi được API trong test) → empty state trung thực
    expect(find.text('Không tìm thấy ưu đãi phù hợp'), findsOneWidget);
  });

  testWidgets('PromotionsScreen search with no match shows honest empty state',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PromotionsScreen(),
      ),
    );
    await tester.pump();

    // Tìm từ khóa không tồn tại → empty state, không còn dữ liệu giả
    await tester.enterText(find.byType(TextField).first, 'zzz-khong-ton-tai');
    await tester.pump();

    expect(find.text('Không tìm thấy ưu đãi phù hợp'), findsOneWidget);

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

    // Tab 1: Trả Góp Nhà & Xe — nội dung chờ chương trình thật từ Backend
    await tester.tap(find.text('Trả Góp Nhà & Xe'));
    await tester.pump();
    expect(find.text('Chương Trình Tài Chính Sen Hồng'), findsOneWidget);
    expect(find.text('Gói Vay Mua Nhà An Cư SenBank'), findsNothing);

    // Tab 2: Sự Kiện — tiêu đề trung thực
    await tester.tap(find.text('Sự Kiện'));
    await tester.pump();
    expect(find.text('Sự kiện đang diễn ra'), findsWidgets);

    // Tab 3: Voucher — khung nhập mã vẫn hoạt động
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
