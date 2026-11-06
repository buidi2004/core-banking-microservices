import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/support/live_chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LiveChatScreen renders AI chatbot header, welcome message, sources and quick replies',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LiveChatScreen(),
      ),
    );
    await tester.pump();

    // Verify AppBar
    expect(find.text('CSKH Sen Hồng'), findsOneWidget);
    expect(find.text('Trực tuyến 24/7 • Phản hồi tức thì'), findsOneWidget);

    // Verify initial AI assistant greeting
    expect(find.text('Trợ Lý AI Sen Hồng'), findsOneWidget);
    expect(find.textContaining('Trợ lý AI Tài chính Thông minh 24/7'), findsOneWidget);

    // Verify source citation chip (Clean Banking UX without .md extension)
    expect(find.text('Cẩm nang Sen Hồng'), findsOneWidget);

    // Verify quick suggestion chips
    expect(find.text('Biểu phí chuyển tiền Napas 247'), findsOneWidget);
    expect(find.text('Lãi suất tiết kiệm online'), findsOneWidget);
    expect(find.text('Quy định sinh trắc học QĐ 2345'), findsOneWidget);
    expect(find.text('Cách mở thẻ Visa miễn phí'), findsOneWidget);

    // Verify message input field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Nhập tin nhắn hỗ trợ...'), findsOneWidget);

    // Verify zero technical leaks of .md extension anywhere on screen
    expect(find.textContaining('.md'), findsNothing);
  });
}

