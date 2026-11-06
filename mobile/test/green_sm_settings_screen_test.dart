import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/settings/green_sm_settings_screen.dart';

/// Bộ kích thước logical (dp) đại diện cho phổ thiết bị thực tế:
/// điện thoại nhỏ → flagship lớn → tablet dọc/ngang → điện thoại ngang
const Map<String, Size> _deviceSizes = {
  'iPhone SE nhỏ (320×568)': Size(320, 568),
  'Android phổ thông (360×640)': Size(360, 640),
  'iPhone 15 (393×852)': Size(393, 852),
  'Android lớn (412×915)': Size(412, 915),
  'Tablet dọc (768×1024)': Size(768, 1024),
  'Tablet ngang (1024×768)': Size(1024, 768),
  'Điện thoại ngang (852×393)': Size(852, 393),
};

void main() {
  testWidgets('GreenSmSettingsScreen renders correctly with 100% match', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GreenSmSettingsScreen(),
      ),
    );
    await tester.pump();

    // Verify header "Cài đặt chung"
    expect(find.text('Cài đặt chung'), findsOneWidget);

    // Verify critical menu items
    expect(find.text('Trở thành tài xế Green SM'), findsOneWidget);
    expect(find.text('Đóng góp bản đồ'), findsOneWidget);
    expect(find.text('Điều khoản & Chính sách'), findsOneWidget);
    expect(find.text('Thông tin công ty'), findsOneWidget);
    expect(find.text('Hợp đồng sử dụng dịch vụ'), findsOneWidget);
    expect(find.text('Kiểm soát quyền riêng tư'), findsOneWidget);

    // Verify second group
    expect(find.text('Quốc gia'), findsOneWidget);
    expect(find.text('Việt Nam'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Bật chế độ tối giản'), findsOneWidget);
    expect(find.text('Được tối ưu hóa cho người cao tuổi và trẻ em'), findsOneWidget);

    // Verify CupertinoSwitch exists
    expect(find.byType(CupertinoSwitch), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Đặt xe'), findsOneWidget);
    expect(find.text('Giao hàng'), findsOneWidget);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Tin nhắn'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);

    // Test toggle switch
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();

    // Test tab selection
    await tester.tap(find.text('Đặt xe'));
    await tester.pumpAndSettle();
  });

  group('Responsive mọi kích thước màn hình', () {
    for (final entry in _deviceSizes.entries) {
      testWidgets('render không tràn layout trên ${entry.key}', (tester) async {
        tester.view
          ..devicePixelRatio = 3.0
          ..physicalSize = entry.value * 3.0; // logical = đúng size khai báo
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(home: GreenSmSettingsScreen()),
        );
        await tester.pump();

        // Không có exception RenderFlex overflow nào trên bất kỳ kích thước nào
        expect(tester.takeException(), isNull,
            reason: 'Tràn layout trên ${entry.key}');
        expect(find.text('Trở thành tài xế Green SM'), findsOneWidget);

        // Cuộn tới item cuối cùng — xác nhận toàn bộ danh sách dùng được
        await tester.dragUntilVisible(
          find.text('Đánh giá Ứng dụng'),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Tràn layout khi cuộn xuống cuối trên ${entry.key}');
        expect(find.text('Đánh giá Ứng dụng'), findsOneWidget);
      });
    }
  });

  testWidgets('tablet: nội dung ≤640dp và bottom bar ≤520dp, căn giữa màn hình', (tester) async {
    tester.view
      ..devicePixelRatio = 2.0
      ..physicalSize = const Size(1280, 800) * 2.0; // logical 1280×800
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: GreenSmSettingsScreen()),
    );
    await tester.pump();

    // Danh sách không giãn full bề ngang tablet
    final listWidth =
        tester.renderObject<RenderBox>(find.byType(ListView).first).size.width;
    expect(listWidth, lessThanOrEqualTo(640));

    // Bottom bar cũng bị giới hạn và căn giữa theo trục ngang màn hình.
    // Đo pill thật (Stack bên trong Align root) thay vì widget root full-width
    final barPill = find.descendant(
      of: find.byType(GreenSmGlassBottomBar),
      matching: find.byType(Stack),
    );
    final pillRect = tester.getRect(barPill);
    expect(pillRect.width, lessThanOrEqualTo(520));
    expect(pillRect.center.dx, closeTo(640, 1.0)); // tâm màn hình 1280/2

    // Chống regression: bar phải neo ĐÁY màn hình, không trôi lên giữa
    // (màn test không có safe inset → lề đáy fallback 16dp)
    expect(pillRect.bottom, closeTo(800 - 16, 1.0));
  });

  testWidgets('điện thoại: nội dung chiếm full bề ngang màn hình', (tester) async {
    tester.view
      ..devicePixelRatio = 3.0
      ..physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: GreenSmSettingsScreen()),
    );
    await tester.pump();

    final listWidth =
        tester.renderObject<RenderBox>(find.byType(ListView).first).size.width;
    expect(listWidth, closeTo(393, 0.5));
  });

  testWidgets('font Be Vietnam Pro bundle được áp dụng cho mọi thành phần chữ', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GreenSmSettingsScreen()),
    );
    await tester.pump();

    // Chữ tiêu đề dòng menu dùng font bundle
    expect(
      tester.widget<Text>(find.text('Trở thành tài xế Green SM')).style?.fontFamily,
      isNull, // inherit=true → lấy fontFamily từ DefaultTextStyle của Theme
    );
    final defaultStyle = DefaultTextStyle.of(
      tester.element(find.text('Trở thành tài xế Green SM')),
    ).style;
    expect(defaultStyle.fontFamily, 'Be Vietnam Pro');

    // Chữ label tab bottom bar cũng inherit đúng font bundle
    final tabStyle = DefaultTextStyle.of(
      tester.element(find.text('Tài khoản')),
    ).style;
    expect(tabStyle.fontFamily, 'Be Vietnam Pro');
  });

  testWidgets('không vỡ layout khi hệ thống phóng chữ 200% (được chặn ở 1.35x)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(
      const MaterialApp(home: GreenSmSettingsScreen()),
    );
    await tester.pump();

    // Hệ số chữ áp dụng thực tế trong màn hình phải bị chặn ở 1.35
    final scaler = MediaQuery.textScalerOf(
      tester.element(find.text('Bật chế độ tối giản')),
    );
    expect(scaler.scale(12.5), closeTo(12.5 * 1.35, 0.01));

    // Không tràn layout kể cả khi người dùng bật chữ lớn hệ thống
    await tester.dragUntilVisible(
      find.text('Đánh giá Ứng dụng'),
      find.byType(ListView),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch vẫn tương tác được
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
  });
}
