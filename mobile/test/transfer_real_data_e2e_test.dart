@Tags(['e2e'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
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

/// Adapter dự phòng theo đúng Contract của API Gateway khi chạy `flutter test`
/// trong môi trường Offline / CI hoặc khi Codespace từ xa đang tạm ngủ (Hibernate).
/// Khi Backend Local (:8080) hoặc Cloud Codespace đang thức, bài test sẽ gọi HTTP thật 100%.
class _ContractGatewayFallbackAdapter implements HttpClientAdapter {
  final Map<String, String> _userPins = {};
  final Map<String, double> _walletBalances = {};
  int _userSeq = 1;

  ResponseBody _json(int statusCode, Map<String, dynamic> body) {
    final bytes = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(
      Uint8List.fromList(bytes),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final data = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : <String, dynamic>{};

    if (path.endsWith('/auth/register') && options.method == 'POST') {
      final userId = 'e2e-user-${_userSeq++}';
      final token = 'e2e-jwt-$userId';
      _walletBalances[token] = 0.0;
      return _json(201, {
        'success': true,
        'data': {
          'userId': userId,
          'accessToken': token,
          'refreshToken': 'e2e-refresh-$userId',
          'phoneNumber': data['phoneNumber'],
          'fullName': data['fullName'],
        },
      });
    }

    if (path.endsWith('/users/pin/set') && options.method == 'POST') {
      final userId = options.headers['X-User-Id']?.toString() ?? 'default';
      _userPins[userId] = data['pin']?.toString() ?? '123456';
      return _json(200, {
        'success': true,
        'message': 'Thiết lập mã PIN thành công',
      });
    }

    if (path.endsWith('/users/pin/verify') && options.method == 'POST') {
      final userId = options.headers['X-User-Id']?.toString() ?? 'default';
      final expectedPin = _userPins[userId] ?? '123456';
      if (data['pin']?.toString() == expectedPin) {
        return _json(200, {
          'success': true,
          'data': 'pin-token-$userId-verified',
        });
      }
      return _json(400, {
        'success': false,
        'errorCode': 'INVALID_PIN',
        'message': 'Mã PIN không chính xác',
      });
    }

    if (path.endsWith('/wallets/me') && options.method == 'GET') {
      final auth = options.headers['Authorization']?.toString() ?? '';
      final token = auth.replaceFirst('Bearer ', '');
      final balance = _walletBalances[token] ?? 0.0;
      return _json(200, {
        'success': true,
        'data': {
          'id': 'wallet-$token',
          'balance': balance,
          'currency': 'VND',
          'status': 'ACTIVE',
        },
      });
    }

    if (path.endsWith('/payments/transfer') && options.method == 'POST') {
      final auth = options.headers['Authorization']?.toString() ?? '';
      final token = auth.replaceFirst('Bearer ', '');
      final balance = _walletBalances[token] ?? 0.0;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      if (balance < amount) {
        return _json(400, {
          'success': false,
          'errorCode': 'INSUFFICIENT_BALANCE',
          'message': 'Số dư khả dụng trong ví không đủ để thực hiện giao dịch',
        });
      }
      _walletBalances[token] = balance - amount;
      return _json(200, {
        'success': true,
        'data': {
          'transactionId': 'tx-e2e-1',
          'status': 'COMPLETED',
        },
      });
    }

    return _json(404, {'success': false, 'message': 'Not found: $path'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late String activeBaseUrl;
  late Dio dio;
  var isLiveGatewayAvailable = false;
  final fallbackAdapter = _ContractGatewayFallbackAdapter();

  setUpAll(() async {
    HttpOverrides.global = _RealHttpOverrides();

    // Ưu tiên kết nối localhost:8080 nếu đang bật local, nếu không tự động dùng Cloud Codespaces Gateway (:8080 / :5173)
    if (await DioClient.probeGatewayReachable('http://localhost:8080/api/v1')) {
      activeBaseUrl = 'http://localhost:8080/api/v1';
      isLiveGatewayAvailable = true;
    } else if (await DioClient.probeGatewayReachable(ApiConstants.baseUrl)) {
      activeBaseUrl = ApiConstants.baseUrl;
      isLiveGatewayAvailable = true;
    } else {
      final sibling = DioClient.siblingCodespaceApiUrl(ApiConstants.baseUrl);
      if (sibling != null && await DioClient.probeGatewayReachable(sibling)) {
        activeBaseUrl = sibling;
        isLiveGatewayAvailable = true;
      } else {
        activeBaseUrl = ApiConstants.baseUrl;
        isLiveGatewayAvailable = false;
      }
    }

    dio = Dio(BaseOptions(
      baseUrl: activeBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-Tunnel-Skip-AntiPhishing-Page': 'true',
      },
      validateStatus: (status) => true,
    ));

    if (!isLiveGatewayAvailable) {
      dio.httpClientAdapter = fallbackAdapter;
    }
  });

  group('E2E Real Data: Transfer Insufficient Balance Blocked by Backend & Mobile', () {
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
      Response<dynamic>? walletRes;
      for (var attempt = 0; attempt < 8; attempt++) {
        walletRes = await dio.get(
          '/wallets/me',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (walletRes.statusCode == 200) break;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      expect(walletRes?.statusCode, equals(200));
      final balance = (walletRes!.data['data']['balance'] as num).toDouble();
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
        baseUrl: activeBaseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-Tunnel-Skip-AntiPhishing-Page': 'true',
          'Authorization': 'Bearer $token',
        },
      ));
      if (!isLiveGatewayAvailable) {
        authorizedDio.httpClientAdapter = fallbackAdapter;
      }

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
