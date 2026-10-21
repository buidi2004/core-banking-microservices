@Tags(['e2e'])
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _RealHttpOverrides();
  });

  group('E2E Real Data: Transfer Insufficient Balance Blocked by Backend & Mobile', () {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api/v1',
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => true,
    ));

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final phoneSender = '091${timestamp.toString().substring(5, 12)}';
    final phoneReceiver = '092${timestamp.toString().substring(5, 12)}';

    late String token;
    late String senderUserId;
    late String receiverUserId;
    late String pinToken;

    test('Step 1: Setup real sender and receiver users with PIN in identity-service', () async {
      // 1. Đăng ký người gửi
      final regSender = await dio.post('/auth/register', data: {
        'phoneNumber': phoneSender,
        'fullName': 'Nguyen Van A E2E Real',
        'password': 'Password123!',
        'deviceId': 'device-e2e-real',
      });
      expect(regSender.statusCode, equals(201));
      token = regSender.data['data']['accessToken'];
      senderUserId = regSender.data['data']['userId'];

      // 2. Thiết lập PIN cho người gửi
      final setPin = await dio.post(
        '/users/pin/set',
        data: {'pin': '123456'},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-User-Id': senderUserId,
        }),
      );
      expect(setPin.statusCode, equals(200));

      // 3. Đăng ký người nhận
      final regReceiver = await dio.post('/auth/register', data: {
        'phoneNumber': phoneReceiver,
        'fullName': 'Tran Thi B E2E Real',
        'password': 'Password123!',
        'deviceId': 'device-e2e-real-receiver',
      });
      expect(regReceiver.statusCode, equals(201));
      receiverUserId = regReceiver.data['data']['userId'];

      // 4. Xác thực mã PIN lấy pinToken
      final verifyPin = await dio.post(
        '/users/pin/verify',
        data: {'pin': '123456'},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-User-Id': senderUserId,
        }),
      );
      expect(verifyPin.statusCode, equals(200));
      pinToken = verifyPin.data['data'];
      expect(pinToken, isNotEmpty);
    });

    test('Step 2: Check wallet balance is 0 VND', () async {
      final walletRes = await dio.get(
        '/wallets/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(walletRes.statusCode, equals(200));
      final balance = (walletRes.data['data']['balance'] as num).toDouble();
      expect(balance, equals(0.0));
    });

    test('Step 3: Transfer with insufficient balance fails with HTTP 400 & INSUFFICIENT_BALANCE', () async {
      final transferRes = await dio.post(
        '/payments/transfer',
        data: {
          'sourceUserId': senderUserId,
          'targetUserId': receiverUserId,
          'amount': 300000,
          'currency': 'VND',
          'note': 'E2E insufficient balance test',
          'idempotencyKey': 'e2e-transfer-insufficient-$timestamp',
          'pinToken': pinToken,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-Pin-Token': pinToken,
        }),
      );

      // Backend phải trả về HTTP 400 Bad Request
      expect(transferRes.statusCode, equals(400));
      expect(transferRes.data['success'], isFalse);
      expect(transferRes.data['errorCode'], equals('INSUFFICIENT_BALANCE'));
      expect(transferRes.data['message'], contains('Số dư khả dụng trong ví không đủ'));

      // Error message trích xuất cho UI phải rõ ràng
      final uiMessage = extractErrorMessage(transferRes.data['message']);
      expect(uiMessage, contains('Số dư khả dụng'));
    });

    test('Step 4: TransferRemoteDataSource.initTransfer throws Exception when balance is insufficient', () async {
      final authorizedDio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8080/api/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final transferDs = TransferRemoteDataSource(
        dio: authorizedDio,
        serverSideTransferAuth: true,
      );

      expect(
        () => transferDs.initTransfer(
          sourceUserId: senderUserId,
          targetUserId: receiverUserId,
          amount: 500000,
          note: 'E2E insufficient balance',
          pinToken: pinToken,
          idempotencyKey: 'e2e-ds-insufficient-$timestamp',
        ),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          equals(400),
        )),
      );
    });

    test('Step 5: Verify balance remains 0 VND and was NOT deducted', () async {
      final walletRes = await dio.get(
        '/wallets/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(walletRes.statusCode, equals(200));
      final balance = (walletRes.data['data']['balance'] as num).toDouble();
      expect(balance, equals(0.0));
    });
  });
}
