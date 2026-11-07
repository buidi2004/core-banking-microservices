import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/widgets/animated_hint_ticker.dart';
import 'package:sen_hong_bank/presentation/widgets/sen_hong_smart_sliver_app_bar.dart';

void main() {
  group('SenHongSmartSliverAppBar & SenHongSmartHeaderBar Tests', () {
    testWidgets('renders SenHongSmartHeaderBar with asymmetric rounded corner and gradient box',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SenHongSmartHeaderBar(),
          ),
        ),
      );

      // Kiểm tra góc bo cong lệch bên trái 34dp
      final containerFinder = find.byType(Container).first;
      expect(containerFinder, findsOneWidget);

      // Kiểm tra chữ gợi ý đầu tiên xuất hiện
      expect(find.text('Dán chuyển tiền AI'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('AnimatedHintTicker loops through hints smoothly', (tester) async {
      final hints = ['Dán chuyển tiền AI', 'Tìm kiếm dịch vụ', 'Săn ưu đãi'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedHintTicker(
              hints: hints,
              interval: const Duration(seconds: 2),
            ),
          ),
        ),
      );

      // Ban đầu hiện hint[0]
      expect(find.text('Dán chuyển tiền AI'), findsOneWidget);
      expect(find.text('Tìm kiếm dịch vụ'), findsNothing);

      // Sau 2 giây -> đổi sang hint[1]
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Tìm kiếm dịch vụ'), findsOneWidget);

      // Sau 2 giây tiếp theo -> đổi sang hint[2]
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Săn ưu đãi'), findsOneWidget);

      // Sau 2 giây tiếp -> vòng lại hint[0]
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Dán chuyển tiền AI'), findsOneWidget);
    });

    testWidgets('renders SliverAppBar with floating, snap and asymmetric rounded corner',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SenHongSmartSliverAppBar(),
                SliverFillRemaining(
                  child: Center(child: Text('Content')),
                ),
              ],
            ),
          ),
        ),
      );

      final sliverAppBarFinder = find.byType(SliverAppBar);
      expect(sliverAppBarFinder, findsOneWidget);

      final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
      expect(sliverAppBar.floating, isTrue);
      expect(sliverAppBar.snap, isTrue);
      expect(sliverAppBar.pinned, isFalse);
      expect(sliverAppBar.elevation, 0);
      expect(sliverAppBar.scrolledUnderElevation, 0);

      expect(sliverAppBar.shape, isA<RoundedRectangleBorder>());
      final shape = sliverAppBar.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius.bottomLeft, const Radius.circular(34));
      expect(borderRadius.bottomRight, Radius.zero);

      expect(find.text('Dán chuyển tiền AI'), findsOneWidget);
    });

    testWidgets('triggers callbacks on tap in SenHongSmartHeaderBar', (tester) async {
      bool pasteAiTapped = false;
      bool notifTapped = false;
      bool menuTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SenHongSmartHeaderBar(
              onPasteAi: () => pasteAiTapped = true,
              onNotificationTap: () => notifTapped = true,
              onMenuTap: () => menuTapped = true,
              hasUnreadNotification: true,
            ),
          ),
        ),
      );

      // Tap on search box
      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(pasteAiTapped, isTrue);

      // Tap on Notifications icon
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(notifTapped, isTrue);

      // Tap on Menu icon
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(menuTapped, isTrue);
    });
  });
}
