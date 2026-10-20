import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays clear session expired dialog and banner when sessionExpired is true', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(sessionExpired: true),
      ),
    );

    // Initial pump
    await tester.pump();
    // Pump post-frame callbacks for dialog
    await tester.pump(const Duration(milliseconds: 100));

    // Verify clear login requirement notice
    expect(find.text('Yêu Cầu Đăng Nhập'), findsWidgets);
    expect(find.text('Yêu Cầu Đăng Nhập Lại'), findsOneWidget);

    // Dismiss dialog
    if (find.text('Đăng nhập ngay').evaluate().isNotEmpty) {
      await tester.tap(find.text('Đăng nhập ngay'));
      await tester.pumpAndSettle();
    }

    // Banner remains on the screen
    expect(find.text('Yêu Cầu Đăng Nhập Lại'), findsOneWidget);
  });
}
