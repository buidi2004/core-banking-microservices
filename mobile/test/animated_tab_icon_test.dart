import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/presentation/widgets/animated_tab_icon.dart';

void main() {
  group('AnimatedTabIcon Widget Tests', () {
    testWidgets('renders unselected icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedTabIcon(
                icon: LucideIcons.house,
                isSelected: false,
                color: Colors.grey,
                tabType: AnimatedTabType.home,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.house), findsOneWidget);
    });

    testWidgets('animates and bounces when selected changes to true', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => isSelected = true),
                    child: AnimatedTabIcon(
                      icon: LucideIcons.gift,
                      isSelected: isSelected,
                      color: Colors.blue,
                      tabType: AnimatedTabType.gift,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byIcon(LucideIcons.gift), findsOneWidget);

      // Tap to trigger selection animation
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // Start controller
      await tester.pump(const Duration(milliseconds: 150)); // Mid-bounce
      await tester.pump(const Duration(milliseconds: 300)); // Elastic settling
      await tester.pump(const Duration(milliseconds: 500)); // Finished

      expect(find.byIcon(LucideIcons.gift), findsOneWidget);
    });

    testWidgets('supports semantic movements for all tab types', (tester) async {
      for (final type in [
        AnimatedTabType.home,
        AnimatedTabType.cards,
        AnimatedTabType.gift,
        AnimatedTabType.more,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedTabIcon(
                  icon: LucideIcons.sparkles,
                  isSelected: true,
                  color: Colors.amber,
                  tabType: type,
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      }
    });
  });
}
