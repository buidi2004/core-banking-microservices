import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen mounts and renders without errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump forward in time through Phase 1 (500ms)
    await tester.pump(const Duration(milliseconds: 500));

    // Pump forward into Phase 2 (1500ms)
    await tester.pump(const Duration(milliseconds: 1000));

    // Pump forward into Phase 3 (2500ms)
    await tester.pump(const Duration(milliseconds: 1000));

    // Pump to 3400ms (Peak bloom & Flash)
    await tester.pump(const Duration(milliseconds: 900));

    // Pump to 3750ms (Hold frame)
    await tester.pump(const Duration(milliseconds: 350));

    // Pump to 4000ms (Exit transition complete)
    await tester.pump(const Duration(milliseconds: 250));

    // Clean teardown
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('SplashScreen tap triggers navigation early without exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();

    // Tap to skip
    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('SplashScreen handles expired JWT gracefully without errors', (tester) async {
    // expired token (exp: 1000000000)
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEwMDAwMDAwMDAsInN1YiI6InVzZXIxMjMifQ.mock_sig',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Must still mount safely
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('SplashScreen handles valid unexpired JWT gracefully', (tester) async {
    // Valid token exp in 2099 (4070908800)
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjQwNzA5MDg4MDAsInN1YiI6InVzZXIxMjMifQ.mock_sig',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
