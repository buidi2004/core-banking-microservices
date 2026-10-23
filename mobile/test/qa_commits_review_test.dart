import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/notification_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';

/// BỘ KIỂM THỬ TỰ ĐỘNG QA / QC CHO 5 COMMITS GẦN NHẤT
/// Đảm bảo tính toàn vẹn của nghiệp vụ tài chính, bảo mật và tương thích client-server.
void main() {
  group('QA Test Suite 1: Commit 4ceedcb & 21fbcff - Cấu hình mạng & Bóc tách lỗi Dio', () {
    test('TC-NET-01: ApiConstants trỏ mặc định vào Gateway (/api/v1) & Native WebSocket (/ws-native)', () {
      expect(ApiConstants.baseUrl, endsWith('/api/v1'));
      expect(
        ApiConstants.baseUrl.startsWith('http://localhost:8080') ||
            ApiConstants.baseUrl.contains('.app.github.dev'),
        isTrue,
      );
      expect(ApiConstants.wsUrl, endsWith('/ws-native'));
      expect(ApiConstants.transactions, equals('/transactions'));
      expect(ApiConstants.walletMe, equals('/wallets/me'));
    });

    test('TC-ERR-02: extractErrorMessage bóc tách lỗi chi tiết từ DioException thay vì báo mất mạng', () {
      final dioErrorWithField = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Dữ liệu gửi lên không đúng định dạng',
            'data': {'phoneNumber': 'Invalid Vietnamese phone number format'},
            'error': 'VALIDATION_FAILED',
          },
        ),
      );

      final msg = extractErrorMessage(dioErrorWithField);
      expect(msg, contains('Số điện thoại không đúng định dạng Việt Nam'));
      expect(msg, isNot(contains('Không thể kết nối đến máy chủ')));
    });

    test('TC-ERR-03: extractErrorMessage bóc tách thông báo đăng nhập sai mật khẩu', () {
      final dioErrorLogin = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Thông tin đăng nhập hoặc mật khẩu không chính xác. Còn 4 lần thử.',
            'error': 'BAD_REQUEST',
          },
        ),
      );

      final msg = extractErrorMessage(dioErrorLogin);
      expect(msg, equals('Thông tin đăng nhập hoặc mật khẩu không chính xác. Còn 4 lần thử.'));
    });

    test('TC-VAL-04: Kiểm thử tính hợp lệ của Regex số điện thoại di động Việt Nam', () {
      final phoneRegex = RegExp(r'^(0|\+84)[35789][0-9]{8}$');

      // Các đầu số hợp lệ (10 số, đầu 03, 05, 07, 08, 09)
      expect(phoneRegex.hasMatch('0988776655'), isTrue);
      expect(phoneRegex.hasMatch('0912345678'), isTrue);
      expect(phoneRegex.hasMatch('0386668888'), isTrue);
      expect(phoneRegex.hasMatch('0771234567'), isTrue);
      expect(phoneRegex.hasMatch('0521234567'), isTrue);
      expect(phoneRegex.hasMatch('+84988776655'), isTrue);

      // Các đầu số không hợp lệ (sai đầu số, sai độ dài, có chữ cái)
      expect(phoneRegex.hasMatch('1234567890'), isFalse);
      expect(phoneRegex.hasMatch('0123456789'), isFalse);
      expect(phoneRegex.hasMatch('098877665'), isFalse);
      expect(phoneRegex.hasMatch('09887766555'), isFalse);
      expect(phoneRegex.hasMatch('abcdefghij'), isFalse);
    });
  });

  group('QA Test Suite 2: Commit aba2737 - Lịch sử giao dịch & Snapshot số dư (V4 Migration)', () {
    test('TC-TX-01: TransactionRemoteDataSource xử lý đúng cấu trúc phân trang Map từ TransactionHistoryController', () async {
      final dioMock = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      dioMock.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Transactions retrieved',
              'data': {
                'content': [
                  {
                    'transactionId': 'tx-123',
                    'transactionCode': 'TXN_001',
                    'type': 'TRANSFER_OUT',
                    'status': 'SUCCESS',
                    'amount': 50000,
                    'fee': 0,
                    'currency': 'VND',
                    'note': 'QA Test',
                    'runningBalance': 850000,
                    'balanceAfter': 850000,
                    'createdAt': '2026-10-20T04:32:15Z',
                    'sourceWalletId': 'wallet-a',
                    'targetWalletId': 'wallet-b',
                  }
                ],
                'page': 0,
                'size': 20,
                'totalElements': 1,
                'totalPages': 1,
                'last': true,
              }
            },
          ));
        },
      ));

      final ds = TransactionRemoteDataSource(dio: dioMock);
      final page = await ds.getTransactionsPage(walletId: 'wallet-a');

      expect(page['totalElements'], equals(1));
      expect(page['isLast'], isTrue);
      final items = page['items'] as List<Map<String, dynamic>>;
      expect(items.length, equals(1));
      expect(items.first['id'], equals('tx-123'));
      expect(items.first['runningBalance'], equals(850000.0));
      expect(items.first['amount'], equals(-50000.0));
      expect(items.first['type'], equals('transfer_out'));
    });
  });

  group('QA Test Suite 3: Commit aba2737 - Notification JSONB Payload & Biến động số dư', () {
    test('TC-NOTIF-01: NotificationRemoteDataSource bóc tách đúng cú pháp SMS Banking biến động số dư', () async {
      final dioMock = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      dioMock.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Notifications retrieved',
              'data': {
                'content': [
                  {
                    'id': 'notif-001',
                    'userId': 'user-alice',
                    'title': 'Biến động số dư: Chuyển tiền',
                    'body': 'TK 0982575055 GD thành công. PS: -50.000 VND. SD: 850.000 VND - Đến: 0972575055 - ND: QA Test Transfer',
                    'channel': 'FCM',
                    'isRead': false,
                    'dataPayload': jsonEncode({
                      'transactionId': 'tx-p2p-001',
                      'type': 'TRANSFER_OUT',
                      'amount': 50000.0,
                      'newBalance': 850000.0,
                    }),
                    'createdAt': '2026-10-20T04:32:16Z',
                  },
                  {
                    'id': 'notif-002',
                    'userId': 'user-bob',
                    'title': 'Biến động số dư: Nhận tiền',
                    'body': 'TK 0972575055 GD thành công. PS: +50.000 VND. SD: 150.000 VND - Từ: 0982575055 - ND: QA Test Transfer',
                    'channel': 'FCM',
                    'isRead': false,
                    'dataPayload': jsonEncode({
                      'transactionId': 'tx-p2p-001',
                      'type': 'TRANSFER_IN',
                      'amount': 50000.0,
                      'newBalance': 150000.0,
                    }),
                    'createdAt': '2026-10-20T04:32:16Z',
                  }
                ],
                'page': 0,
                'size': 20,
                'totalElements': 2,
                'totalPages': 1,
                'last': true,
              }
            },
          ));
        },
      ));

      final ds = NotificationRemoteDataSource(dio: dioMock);
      final page = await ds.getNotificationsPage(type: 'ALL');
      final items = page['items'] as List<Map<String, dynamic>>;

      expect(items.length, equals(2));

      // Kiểm tra thông báo người gửi (Alice: tiền ra âm)
      final aliceNotif = items[0];
      expect(aliceNotif['title'], equals('Biến động số dư: Chuyển tiền'));
      expect(aliceNotif['amount'], equals(-50000.0));
      expect(aliceNotif['endingBalance'], equals('850000'));
      expect(aliceNotif['accountNumber'], equals('0982575055'));
      expect(aliceNotif['note'], equals('QA Test Transfer'));

      // Kiểm tra thông báo người nhận (Bob: tiền vào dương)
      final bobNotif = items[1];
      expect(bobNotif['title'], equals('Biến động số dư: Nhận tiền'));
      expect(bobNotif['amount'], equals(50000.0));
      expect(bobNotif['endingBalance'], equals('150000'));
      expect(bobNotif['accountNumber'], equals('0972575055'));
      expect(bobNotif['note'], equals('QA Test Transfer'));
    });
  });
}
