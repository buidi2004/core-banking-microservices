import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/widgets/shader_background.dart';

void main() {
  testWidgets('ShaderBackground renders child and handles lifecycle ticks',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShaderBackground(
            child: Center(
              child: Text('Shader Content'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Shader Content'), findsOneWidget);
    expect(find.byType(ShaderBackground), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump a few frames
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Shader Content'), findsOneWidget);
  });
}

