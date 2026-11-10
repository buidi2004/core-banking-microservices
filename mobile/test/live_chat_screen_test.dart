import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/support/live_chat_screen.dart';
import 'package:sen_hong_bank/presentation/widgets/chatbot_lottie_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LiveChatScreen renders AI chatbot header, welcome message, zero RAG doc leaks, and quick replies',
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

    // Verify zero RAG source citation chips leak (Clean Banking UX: no .md or internal doc chips)
    expect(find.text('Cẩm nang Sen Hồng'), findsNothing);
    expect(find.textContaining('Tư Vấn Nghiệp Vụ'), findsNothing);

    // Verify quick suggestion chips
    expect(find.text('Biểu phí chuyển tiền Napas 247'), findsOneWidget);
    expect(find.text('Lãi suất tiết kiệm online'), findsOneWidget);
    expect(find.text('Quy định sinh trắc học QĐ 2345'), findsOneWidget);
    expect(find.text('Cách mở thẻ Visa miễn phí'), findsOneWidget);

    // Verify message input field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Nhập tin nhắn hỗ trợ...'), findsOneWidget);

    // Verify Full Black Obsidian background
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF000000));

    // Verify zero technical leaks of .md extension anywhere on screen
    expect(find.textContaining('.md'), findsNothing);

    // Verify AI message bubble is aligned flush to the left margin
    final leftAlignedBubbles = tester.widgetList<Align>(find.byType(Align)).where(
          (align) => align.alignment == Alignment.centerLeft,
        );
    expect(leftAlignedBubbles.isNotEmpty, isTrue);

    // Verify avatar only appears in AppBar (1 instance), no repeated avatar next to message bubbles
    expect(find.byType(ChatbotLottieAvatar), findsOneWidget);

    // Verify Assistant Notice banner is visible initially
    expect(
      find.textContaining('Kênh Trợ Lý Tự Động. Kênh kết nối trực tiếp'),
      findsOneWidget,
    );
    final dismissBtn = find.byKey(const Key('dismiss_assistant_notice_button'));
    expect(dismissBtn, findsOneWidget);

    // Tap dismiss button (dấu X) to close the notice banner
    await tester.tap(dismissBtn);
    await tester.pump();

    // Verify notice banner is dismissed and no longer visible
    expect(
      find.textContaining('Kênh Trợ Lý Tự Động. Kênh kết nối trực tiếp'),
      findsNothing,
    );
  });
}

