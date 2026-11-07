import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/widgets/border_beam.dart';

void main() {
  testWidgets('BorderBeam renders child widget and animates beam',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BorderBeam(
              borderRadius: 20,
              child: SizedBox(
                width: 200,
                height: 100,
                child: Text('BorderBeam Content'),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial frame
    expect(find.text('BorderBeam Content'), findsOneWidget);
    expect(find.byType(BorderBeam), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump frames to verify animation controller progresses without error
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('BorderBeam Content'), findsOneWidget);
  });
}

