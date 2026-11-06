import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/widgets/ios_liquid_glass_tab_bar.dart';

void main() {
  testWidgets('IOSLiquidGlassTabBar renders in Icon-Only mode and triggers actions via semantics/icons',
      (tester) async {
    int selectedIndex = 0;
    bool centerActionTriggered = false;

    const items = [
      IOSLiquidGlassTabItem(label: 'Trang chủ', icon: CupertinoIcons.house),
      IOSLiquidGlassTabItem(label: 'Giao dịch', icon: CupertinoIcons.clock),
      IOSLiquidGlassTabItem(label: 'Ưu đãi', icon: CupertinoIcons.gift),
      IOSLiquidGlassTabItem(label: 'Tài khoản', icon: CupertinoIcons.person),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: IOSLiquidGlassTabBar(
            items: items,
            selectedIndex: selectedIndex,
            onTabSelected: (idx) => selectedIndex = idx,
            onCenterAction: () => centerActionTriggered = true,
            centerLabel: 'Quét QR',
          ),
        ),
      ),
    );

    // Verify icons exist
    expect(find.byIcon(CupertinoIcons.house), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.qrcode_viewfinder), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.gift), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.person), findsOneWidget);

    // Verify labels are hidden in Icon-Only mode
    expect(find.text('Trang chủ'), findsNothing);
    expect(find.text('Quét QR'), findsNothing);

    // Tap Center QR
    await tester.tap(find.byIcon(CupertinoIcons.qrcode_viewfinder));
    await tester.pumpAndSettle();
    expect(centerActionTriggered, isTrue);
    expect(selectedIndex, 0); // Active tab did not change

    // Tap 'Ưu đãi' (branch index 2) via Semantics or Icon
    await tester.tap(find.bySemanticsLabel('Ưu đãi'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);

    // Tap 'Tài khoản' (branch index 3)
    await tester.tap(find.bySemanticsLabel('Tài khoản'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);
  });
}

