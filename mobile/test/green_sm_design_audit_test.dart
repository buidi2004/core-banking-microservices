import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons_200.dart';
import 'package:sen_hong_bank/presentation/screens/settings/green_sm_settings_screen.dart';

/// ============================================================================
/// DESIGN AUDIT 100% — màn hình Cài đặt Xanh SM / Green SM
/// ----------------------------------------------------------------------------
/// Kiểm khóa từng giá trị thiết kế theo spec chuẩn:
///   1. BỘ ICON  — đúng IconData Lucide nét mảnh (weight 200 ≈ 1.5–1.75px),
///                 size 22, màu #6B6E70; chevron phải 18, màu #8E8E93
///   2. CHỮ      — Be Vietnam Pro; header 16/w700/#1A1A1A; dòng 14.5/w600/
///                 #222222; phụ đề 12.5/w400; trailing 13.5/#8E8E93
///   3. MÀU      — nền #FBFBF9, divider #EDEDEA 0.5dp, xanh chủ đạo #00B14F
///   4. BỐ CỤC   — padding dòng 18/15, header (16,20,16,8), divider thụt 56dp
/// Test FAIL nếu bất kỳ giá trị nào bị ai đó vô tình sửa lệch spec.
/// ============================================================================
void main() {
  // Bảng ánh xạ icon chuẩn spec Xanh SM (dòng → IconData)
  const expectedIcons = <String, IconData>{
    'Trở thành tài xế Green SM': LucideIcons200.contact,
    'Đóng góp bản đồ': LucideIcons200.map,
    'Điều khoản & Chính sách': LucideIcons200.info,
    'Thông tin công ty': LucideIcons200.building2,
    'Hợp đồng sử dụng dịch vụ': LucideIcons200.fileCheck2,
    'Kiểm soát quyền riêng tư': LucideIcons200.fileEdit,
    'Quốc gia': Icons.public, // quả địa cầu dạng đặc đúng ảnh gốc
    'Ngôn ngữ': LucideIcons200.languages,
    'Bật chế độ tối giản': LucideIcons200.slidersHorizontal,
    'Đăng nhập và bảo mật': LucideIcons200.shieldCheck,
    'Địa chỉ đã lưu': LucideIcons200.heart,
    'Hóa đơn': LucideIcons200.receipt,
    'Đánh giá Ứng dụng': LucideIcons200.star,
  };

  Finder listRowOf(String title) => find
      .ancestor(of: find.text(title), matching: find.byType(Row))
      .first;

  List<Icon> rowIcons(WidgetTester tester, String title) {
    final icons = find.descendant(of: listRowOf(title), matching: find.byType(Icon));
    return icons.evaluate().map((e) => e.widget as Icon).toList();
  }

  /// Icon menu của 1 dòng — chọn theo size 22 (không phụ thuộc thứ tự cây)
  Icon menuIconOf(WidgetTester tester, String title) {
    final icons = rowIcons(tester, title);
    return icons.firstWhere((i) => i.size == 22,
        orElse: () => throw StateError('Không tìm thấy icon 22dp ở "$title"'));
  }

  /// Icon chevron của 1 dòng — chọn theo size 18
  Icon chevronOf(WidgetTester tester, String title) {
    final icons = rowIcons(tester, title);
    return icons.firstWhere((i) => i.size == 18,
        orElse: () => throw StateError('Không tìm thấy chevron 18dp ở "$title"'));
  }

  /// Viewport cao 2400dp để ListView build đủ 13 dòng (bỏ qua ảo hóa),
  /// mọi assertion chạy trên toàn bộ cây widget thật
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 3.0
      ..physicalSize = const Size(393, 2400) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GreenSmSettingsScreen()));
    await tester.pump();
  }

  group('1️⃣ BỘ ICON — đúng icon, nét mảnh, size, màu theo spec', () {
    testWidgets('13 dòng menu ánh xạ đúng IconData Lucide', (tester) async {
      await pumpScreen(tester);

      expectedIcons.forEach((title, expected) {
        final icon = menuIconOf(tester, title);
        expect(icon.icon, expected,
            reason: 'Sai icon của dòng "$title"');
      });
    });

    testWidgets('mọi icon menu: size 22, màu #6B6E70 (xám chì ánh xanh)', (tester) async {
      await pumpScreen(tester);

      expectedIcons.forEach((title, _) {
        final icon = menuIconOf(tester, title);
        expect(icon.size, 22, reason: 'Sai size icon "$title"');
        expect(icon.color, const Color(0xFF6B6E70),
            reason: 'Sai màu icon "$title"');
      });
    });

    testWidgets('mũi tên phải chevronRight 18dp #8E8E93 ở 12 dòng không-toggle',
        (tester) async {
      await pumpScreen(tester);

      for (final title in expectedIcons.keys) {
        if (title == 'Bật chế độ tối giản') continue; // dòng toggle, không chevron
        final chevron = chevronOf(tester, title);
        expect(chevron.icon, LucideIcons200.chevronRight,
            reason: 'Sai chevron của "$title"');
        expect(chevron.size, 18, reason: 'Sai size chevron "$title"');
        expect(chevron.color, const Color(0xFF8E8E93),
            reason: 'Sai màu chevron "$title"');
      }
    });

    testWidgets('dòng "Bật chế độ tối giản" KHÔNG có chevron (chỉ switch)',
        (tester) async {
      await pumpScreen(tester);
      final icons = find.descendant(
          of: listRowOf('Bật chế độ tối giản'), matching: find.byType(Icon));
      expect(icons.evaluate().length, 1, reason: 'Chỉ được có đúng 1 icon menu');
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });
  });

  group('2️⃣ KIỂU CHỮ — Be Vietnam Pro, size/weight/màu từng cấp', () {
    testWidgets('mọi chữ trên màn hình dùng font bundle "Be Vietnam Pro"',
        (tester) async {
      await pumpScreen(tester);

      final texts = find.byType(Text).evaluate();
      expect(texts.length, greaterThan(20));
      for (final element in texts) {
        final style = DefaultTextStyle.of(element).style;
        expect(style.fontFamily, 'Be Vietnam Pro',
            reason: 'Chữ "${(element.widget as Text).data}" sai font');
      }
    });

    testWidgets('header "Cài đặt chung": 16dp / w700 / #1A1A1A', (tester) async {
      await pumpScreen(tester);
      final style = tester
          .widget<Text>(find.text('Cài đặt chung'))
          .style!;
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, const Color(0xFF1A1A1A));
    });

    testWidgets('13 tiêu đề dòng: 14.5dp / w600 / #222222 / letterSpacing -0.1',
        (tester) async {
      await pumpScreen(tester);

      for (final title in expectedIcons.keys) {
        final style = tester.widget<Text>(find.text(title)).style!;
        expect(style.fontSize, 14.5, reason: 'Sai cỡ chữ "$title"');
        expect(style.fontWeight, FontWeight.w600, reason: 'Sai độ đậm "$title"');
        expect(style.color, const Color(0xFF222222), reason: 'Sai màu chữ "$title"');
        expect(style.letterSpacing, -0.1, reason: 'Sai letterSpacing "$title"');
      }
    });

    testWidgets('phụ đề chế độ tối giản: 12.5dp / w400 / màu tối ưu WCAG AA',
        (tester) async {
      await pumpScreen(tester);
      final style = tester
          .widget<Text>(find.text('Được tối ưu hóa cho người cao tuổi và trẻ em'))
          .style!;
      expect(style.fontSize, 12.5);
      expect(style.fontWeight, FontWeight.w400);
      // Lệch có chủ đích so với spec #757575: trên nền #FBFBF9, #757575 chỉ đạt
      // ~4.45:1 (dưới ngưỡng AA 4.5:1) — dùng #63666A đạt ~5.6:1
      expect(style.color, const Color(0xFF63666A));
    });

    testWidgets('trailing "Việt Nam"/"Tiếng Việt": 13.5dp / #8E8E93',
        (tester) async {
      await pumpScreen(tester);
      for (final trailing in ['Việt Nam', 'Tiếng Việt']) {
        final style = tester.widget<Text>(find.text(trailing)).style!;
        expect(style.fontSize, 13.5, reason: 'Sai cỡ chữ trailing "$trailing"');
        expect(style.color, const Color(0xFF8E8E93),
            reason: 'Sai màu trailing "$trailing"');
      }
    });
  });

  group('3️⃣ MÀU & NỀN — đúng bảng màu Xanh SM', () {
    testWidgets('nền màn hình #FBFBF9 (trắng ngà nhẹ)', (tester) async {
      await pumpScreen(tester);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFBFBF9));
    });

    testWidgets('divider hairline: 0.5dp, #EDEDEA, đúng 11 đường (6+6 giữa 13 dòng)',
        (tester) async {
      await pumpScreen(tester);
      final dividers = find.byType(Divider);
      expect(dividers, findsNWidgets(11));
      for (final d in dividers.evaluate()) {
        final divider = d.widget as Divider;
        expect(divider.thickness, 0.5);
        expect(divider.color, const Color(0xFFEDEDEA));
      }
    });

    testWidgets('switch chế độ tối giản: track active #00B14F (xanh lục bảo)',
        (tester) async {
      await pumpScreen(tester);
      final sw = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
      expect(sw.activeTrackColor, const Color(0xFF00B14F));
    });
  });

  group('4️⃣ BỐ CỤC — padding, thụt lề chuẩn ảnh mẫu', () {
    testWidgets('dòng menu: padding ngang 18 / dọc 15; icon cách chữ 16dp',
        (tester) async {
      await pumpScreen(tester);

      // Padding của dòng menu — khớp đúng EdgeInsets(18, 15) theo spec
      final paddingElement = find
          .ancestor(
              of: find.text('Đóng góp bản đồ'),
              matching: find.byWidgetPredicate((w) =>
                  w is Padding &&
                  w.padding ==
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 15)))
          .evaluate()
          .single;
      final paddingBox = paddingElement.renderObject! as RenderBox;

      // Icon menu 22dp — định vị qua widget để không nhầm với chevron 18dp
      final menuIcon = menuIconOf(tester, 'Đóng góp bản đồ');
      final iconBox = tester.renderObject<RenderBox>(find.byWidget(menuIcon));

      // Padding ngang 18: icon bắt đầu cách mép trái 18dp
      expect(iconBox.localToGlobal(Offset.zero).dx, closeTo(18, 0.5));
      // Chiều cao dòng = 22 (icon) + 2*15 (padding dọc) = 52dp chuẩn Fitts
      expect(paddingBox.size.height, closeTo(52, 0.5));
    });

    testWidgets('header nhóm thụt (16, 20, 16, 8) theo ảnh mẫu', (tester) async {
      await pumpScreen(tester);
      final headerPadding = tester.widget<Padding>(
        find.ancestor(of: find.text('Cài đặt chung'), matching: find.byType(Padding)).first,
      );
      expect(headerPadding.padding, const EdgeInsets.fromLTRB(16, 20, 16, 8));
    });

    testWidgets('divider thụt lề trái 56dp = 18 padding + 22 icon + 16 gap',
        (tester) async {
      await pumpScreen(tester);
      final firstDivider = tester.renderObject<RenderBox>(find.byType(Divider).first);
      expect(firstDivider.localToGlobal(Offset.zero).dx, closeTo(56, 0.5));
    });
  });

  group('5️⃣ BOTTOM BAR GLASS — chữ/icon tab chuẩn hệ thống', () {
    testWidgets('label tab 10.5dp: w600 khi chọn / w500 khi không chọn',
        (tester) async {
      await pumpScreen(tester);

      expect(
        tester.widget<Text>(find.text('Tài khoản')).style!.fontWeight,
        FontWeight.w600, // đang chọn
      );
      expect(
        tester.widget<Text>(find.text('Đặt xe')).style!.fontWeight,
        FontWeight.w500,
      );
      for (final label in ['Đặt xe', 'Giao hàng', 'Hoạt động', 'Tin nhắn']) {
        expect(
          tester.widget<Text>(find.text(label)).style!.fontSize,
          10.5,
          reason: 'Sai cỡ chữ tab "$label"',
        );
      }
    });

    testWidgets('tab đang chọn màu xanh #00B14F, không chọn #8E8E93',
        (tester) async {
      await pumpScreen(tester);

      expect(tester.widget<Icon>(
        find.descendant(of: find.ancestor(of: find.text('Tài khoản'),
            matching: find.byType(Column)).first, matching: find.byType(Icon)),
      ).color, const Color(0xFF00B14F));
      expect(tester.widget<Icon>(
        find.descendant(of: find.ancestor(of: find.text('Đặt xe'),
            matching: find.byType(Column)).first, matching: find.byType(Icon)),
      ).color, const Color(0xFF8E8E93));
    });
  });
}
