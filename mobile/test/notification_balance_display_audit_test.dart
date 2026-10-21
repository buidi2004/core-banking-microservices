import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/utils/notification_parser.dart';
import 'package:sen_hong_bank/data/datasources/remote/notification_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/screens/history/transaction_history_screen.dart';
import 'package:sen_hong_bank/presentation/screens/home/notifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M-02 & M-03: NotificationParser Unit Tests', () {
    test('Case 1 (M-02): Nguồn có fee (source transfer out) -> âm bao gồm cả phí', () {
      // Source transfer 100,000 VND + 5,000 VND fee -> displayAmount = 105,000
      final metadata = {
        'transactionId': 'tx-source-001',
        'type': 'TRANSFER_OUT',
        'status': 'SUCCESS',
        'transactionAmount': '105000',
        'amount': '105000',
        'newBalance': '18895000',
      };
      const body = 'TK 0982575055 GD thành công. PS: -105.000 VND. SD: 18.895.000 VND - Đến: 0972575055 - ND: Chuyển tiền ăn trưa';

      final amount = NotificationParser.parseAmount(
        metadata: metadata,
        body: body,
        type: 'TRANSFER_OUT',
      );
      expect(amount, equals(-105000.0));

      final endingBalance = NotificationParser.parseEndingBalance(
        metadata: metadata,
        body: body,
      );
      expect(endingBalance, equals('18895000'));
    });

    test('Case 2 (M-02): Đích không có fee (target transfer in) -> dương đúng số tiền chuyển', () {
      // Target receives 100,000 VND (no fee charged to recipient)
      final metadata = {
        'transactionId': 'tx-target-001',
        'type': 'TRANSFER_IN',
        'status': 'SUCCESS',
        'transactionAmount': '100000',
        'amount': '100000',
        'newBalance': '19100000',
      };
      const body = 'TK 0972575055 GD thành công. PS: +100.000 VND. SD: 19.100.000 VND - Từ: 0982575055 - ND: Chuyển tiền ăn trưa';

      final amount = NotificationParser.parseAmount(
        metadata: metadata,
        body: body,
        type: 'TRANSFER_IN',
      );
      expect(amount, equals(100000.0));

      final endingBalance = NotificationParser.parseEndingBalance(
        metadata: metadata,
        body: body,
      );
      expect(endingBalance, equals('19100000'));
    });

    test('Case 3 (M-02): Giao dịch hoàn tiền (REVERSED) -> ví nguồn được cộng lại tiền (dương)', () {
      // Reversal: source wallet is refunded amount + fee -> status REVERSED, payloadType TRANSFER_IN
      final metadata = {
        'transactionId': 'tx-reversal-001',
        'type': 'TRANSFER_IN',
        'status': 'REVERSED',
        'transactionAmount': '105000',
        'amount': '105000',
        'newBalance': '19000000',
      };
      const body = 'TK 0982575055 GD hoàn tiền. PS: +105.000 VND. SD: 19.000.000 VND - Từ: 0972575055 - ND: Hoàn tiền giao dịch thất bại';

      final amount = NotificationParser.parseAmount(
        metadata: metadata,
        body: body,
        type: 'TRANSFER_IN',
      );
      expect(amount, equals(105000.0));

      final endingBalance = NotificationParser.parseEndingBalance(
        metadata: metadata,
        body: body,
      );
      expect(endingBalance, equals('19000000'));
    });

    test('Case 4 (M-02): Giao dịch số tiền bằng 0 -> trả về 0.0 an toàn', () {
      final metadata = {
        'transactionId': 'tx-zero-001',
        'type': 'BALANCE_CHECK',
        'transactionAmount': 0,
        'amount': 0,
      };
      const body = 'Thông báo kiểm tra tài khoản hoạt động';

      final amount = NotificationParser.parseAmount(
        metadata: metadata,
        body: body,
        type: 'BALANCE_CHECK',
      );
      expect(amount, equals(0.0));
    });

    test('Fallback regex parsing khi metadata không có amount', () {
      // Body có PS: -75.000 VND
      const deductBody = 'TK 0982575055 GD thành công. PS: -75.000 VND. SD: 1.000.000 VND';
      final deductAmount = NotificationParser.parseAmount(body: deductBody);
      expect(deductAmount, equals(-75000.0));

      // Body có PS: +80.000 VND
      const creditBody = 'TK 0972575055 GD thành công. PS: +80.000 VND. SD: 2.000.000 VND';
      final creditAmount = NotificationParser.parseAmount(body: creditBody);
      expect(creditAmount, equals(80000.0));
    });

    test('Bóc tách số tài khoản và nội dung ghi chú (accountNumber, note)', () {
      const body = 'TK 0982575055 GD thành công. PS: -50.000 VND. SD: 850.000 VND - Đến: 0972575055 - ND: Mua cafe sáng';
      expect(NotificationParser.parseAccountNumber(body: body), equals('0982575055'));
      expect(NotificationParser.parseNote(body: body), equals('Mua cafe sáng'));
    });
  });

  group('M-02 & M-03: NotificationRemoteDataSource Integration', () {
    test('NotificationRemoteDataSource parses amount and endingBalance correctly from BE payload', () async {
      final dioMock = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      dioMock.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'content': [
                  {
                    'id': 'notif-fee-01',
                    'userId': 'user-1',
                    'title': 'Biến động số dư: Chuyển tiền',
                    'body': 'TK 0982575055 GD thành công. PS: -105.000 VND. SD: 18.895.000 VND - Đến: 0972575055 - ND: GD có phí 5k',
                    'channel': 'FCM',
                    'isRead': false,
                    'dataPayload': jsonEncode({
                      'transactionId': 'tx-101',
                      'type': 'TRANSFER_OUT',
                      'amount': '105000',
                      'transactionAmount': '105000',
                      'newBalance': '18895000',
                    }),
                    'createdAt': '2026-10-20T10:00:00Z',
                  },
                ],
                'last': true,
                'totalElements': 1,
                'totalPages': 1,
              },
            },
          ));
        },
      ));

      final ds = NotificationRemoteDataSource(dio: dioMock);
      final page = await ds.getNotificationsPage(type: 'BALANCE');
      final items = page['items'] as List<Map<String, dynamic>>;

      expect(items.length, equals(1));
      final item = items.first;
      expect(item['amount'], equals(-105000.0));
      expect(item['endingBalance'], equals('18895000'));
      expect(item['accountNumber'], equals('0982575055'));
      expect(item['note'], equals('GD có phí 5k'));
    });
  });

  group('M-01: NotificationsScreen Tab Gating Tests', () {
    testWidgets('Tab Khuyến mãi và Hệ thống hiển thị Tính năng sắp ra mắt (BE-REQ-PROMO)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Thông Báo'), findsOneWidget);
      expect(find.text('Biến động số dư'), findsOneWidget);
      expect(find.text('Khuyến mãi'), findsOneWidget);
      expect(find.text('Hệ thống'), findsOneWidget);

      // Chuyển sang Tab 1: Khuyến mãi
      await tester.tap(find.text('Khuyến mãi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (!BackendCapabilities.promoAndSystemNotifications) {
        expect(find.text('Tính năng sắp ra mắt'), findsOneWidget);
        expect(find.textContaining('BE-REQ-PROMO'), findsOneWidget);
      }

      // Chuyển sang Tab 2: Hệ thống
      await tester.tap(find.text('Hệ thống'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (!BackendCapabilities.promoAndSystemNotifications) {
        expect(find.text('Tính năng sắp ra mắt'), findsOneWidget);
        expect(find.textContaining('Hệ thống'), findsWidgets);
      }
    });
  });

  group('M-04: TransactionHistoryScreen Filter Gating Tests', () {
    testWidgets('Filter Nạp / Rút và Hóa đơn hiển thị Tính năng sắp ra mắt (BE-REQ-06)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Lịch Sử Giao Dịch'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chuyển tiền'), findsOneWidget);
      expect(find.text('Nạp / Rút'), findsOneWidget);
      expect(find.text('Hóa đơn'), findsOneWidget);

      // Chọn Filter 2: Nạp / Rút
      await tester.tap(find.text('Nạp / Rút'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tính năng sắp ra mắt'), findsOneWidget);
      expect(find.textContaining('BE-REQ-06'), findsOneWidget);

      // Chọn Filter 3: Hóa đơn
      await tester.tap(find.text('Hóa đơn'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tính năng sắp ra mắt'), findsOneWidget);
      expect(find.textContaining('BE-REQ-06'), findsOneWidget);
    });
  });
}
