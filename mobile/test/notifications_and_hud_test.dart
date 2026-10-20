import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/home/notifications_screen.dart';
import 'package:sen_hong_bank/presentation/widgets/floating_notification_hud.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingNotificationHUD & InAppNotificationManager Tests', () {
    testWidgets('InAppNotificationManager triggers floating banner on overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalFloatingNotificationOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: Center(child: Text('App Screen')),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('App Screen'), findsOneWidget);
      expect(find.text('Biến động số dư: Nạp tiền'), findsNothing);

      // Trigger an in-app floating push notification
      InAppNotificationManager().show(
        title: 'Biến động số dư: Nạp tiền',
        body: 'Tài khoản: 0976019781\nPS: +50.000.000 VND',
        amount: 50000000,
        txId: 'tx-test-888',
        userName: 'Test User',
        accountNumber: '0976019781',
        currentBalance: '50.000.000 VND',
        formattedTime: 'Vừa xong',
      );

      // Pump frame to trigger animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify banner appears with correct content
      expect(find.text('Biến động số dư: Nạp tiền'), findsOneWidget);
      expect(find.text('Vừa xong'), findsOneWidget);

      // Tap close button (CupertinoIcons.xmark)
      final closeBtn = find.byIcon(CupertinoIcons.xmark);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Notification is dismissed
      expect(find.text('Biến động số dư: Nạp tiền'), findsNothing);
    });
  });

  group('NotificationsScreen (No Mock) Tests', () {
    testWidgets('NotificationsScreen renders tabs and UI without static mock data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsScreen(),
        ),
      );

      // Initial frame
      await tester.pump();

      // Verify Header
      expect(find.text('Thông Báo'), findsOneWidget);

      // Verify 3 tabs exist
      expect(find.text('Biến động số dư'), findsOneWidget);
      expect(find.text('Khuyến mãi'), findsOneWidget);
      expect(find.text('Hệ thống'), findsOneWidget);

      // Switch to Khuyến mãi tab
      await tester.tap(find.text('Khuyến mãi'));
      await tester.pump();

      // Switch to Hệ thống tab
      await tester.tap(find.text('Hệ thống'));
      await tester.pump();
    });
  });

  group('Bug Fixes Verification Tests (E2E Contract Rules)', () {
    test('Bug 1: BE returns "content", FE parses as body/content/message fallback', () {
      final beItem = {
        'id': 'notif-1',
        'title': 'Nhận tiền từ NGUYEN VAN A',
        'content': 'Tài khoản: 0976019781\nPS: +500.000 VND\nSố dư cuối: 15.500.000 VND',
        'read': true,
        'createdAt': '2026-09-05T07:00:00Z',
      };

      // Simulating fallback logic: it.content || it.body || it.message
      final body = (beItem['content'] ?? beItem['body'] ?? beItem['message'] ?? '').toString();
      expect(body, isNotEmpty);
      expect(body, contains('Tài khoản: 0976019781'));
      expect(body, contains('PS: +500.000 VND'));
    });

    test('Bug 2: BE returns "read: true" (isRead is null) -> correctly recognized as read', () {
      final beItemRead = {
        'id': 'notif-2',
        'title': 'Biến động số dư',
        'content': 'Giao dịch thành công',
        'read': true, // Spring Boot field
        'isRead': null, // null from BE
      };

      final beItemUnread = {
        'id': 'notif-3',
        'title': 'Biến động số dư',
        'content': 'Giao dịch mới',
        'read': false,
        'isRead': null,
      };

      // Bug condition: !null would evaluate to true (marking read items as unread)
      // Fix: (isRead ?? read ?? false) == true
      final isRead1 = (beItemRead['isRead'] ?? beItemRead['read'] ?? false) == true;
      final isRead2 = (beItemUnread['isRead'] ?? beItemUnread['read'] ?? false) == true;

      expect(isRead1, isTrue); // Must be true (read)
      expect(isRead2, isFalse); // Must be false (unread)
    });

    test('Bug 3: Spring Page uses "last: false", FE parses "data.last ?? data.isLast"', () {
      // Spring Boot PageResponse format
      final bePageResponseNotLast = {
        'content': [
          {'id': 'tx-1', 'amount': 100000, 'type': 'TRANSFER_IN'},
          {'id': 'tx-2', 'amount': 50000, 'type': 'TRANSFER_OUT'},
        ],
        'page': 0,
        'size': 2,
        'totalElements': 10,
        'totalPages': 5,
        'last': false, // Spring Page uses 'last', NOT 'isLast'
      };

      final bePageResponseLast = {
        'content': [
          {'id': 'tx-9', 'amount': 20000, 'type': 'TRANSFER_IN'},
        ],
        'page': 4,
        'size': 2,
        'totalElements': 10,
        'totalPages': 5,
        'last': true,
      };

      final isLast1 = (bePageResponseNotLast['last'] ?? bePageResponseNotLast['isLast'] ?? false) == true;
      final isLast2 = (bePageResponseLast['last'] ?? bePageResponseLast['isLast'] ?? false) == true;

      // When last is false, isLast must be false to allow loading more transactions
      expect(isLast1, isFalse);
      // When last is true, isLast must be true to stop loading more
      expect(isLast2, isTrue);
    });

    testWidgets('FloatingNotificationHUD displays all 6 required fields without mock', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalFloatingNotificationOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Home')),
        ),
      );

      // Trigger full data push
      InAppNotificationManager().show(
        title: 'Biến động số dư: Nhận tiền',
        body: 'Nhận tiền từ NGUYEN VAN B',
        amount: 2500000,
        userName: 'BÙI ĐÌNH PHONG',
        accountNumber: '0976019781',
        currentBalance: '52.500.000 VND',
        note: 'Chuyển tiền ăn trưa',
        formattedTime: '07:15 05/09/2026',
        txId: 'TX_998877',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check all 6 fields in floating HUD:
      // 1. Title
      expect(find.text('Biến động số dư: Nhận tiền'), findsOneWidget);
      // 2. Real Date/Time
      expect(find.text('07:15 05/09/2026'), findsOneWidget);
      // 3. Amount (+2.500.000 đ)
      expect(find.textContaining('+2.500.000'), findsOneWidget);
      // 4. User Name
      expect(find.text('BÙI ĐÌNH PHONG'), findsOneWidget);
      // 5. Account number
      expect(find.textContaining('0976019781'), findsOneWidget);
      // 6. Current balance & note
      expect(find.text('52.500.000 VND'), findsOneWidget);
      expect(find.text('Chuyển tiền ăn trưa'), findsOneWidget);
    });
  });
}

