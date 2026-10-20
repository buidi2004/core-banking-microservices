import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

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

  const String baseUrl = 'http://180.93.120.246:8080/api/v1';
  const String wsUrl = 'ws://180.93.120.246:8080/ws-native';

  final client = HttpClient();
  tearDownAll(() => client.close());

  // Shared test context
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testPhone = '098${timestamp.toString().substring(5, 12)}';
  final receiverPhone = '097${(timestamp + 1).toString().substring(5, 12)}';

  String? accessToken;
  String? refreshToken;
  String? userId;
  String? walletId;
  String? pinToken;
  String? receiverWalletId;
  String? transferTxId;
  String? linkedBankAccountId;

  Future<Map<String, dynamic>> httpReq({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    String? token,
  }) async {
    var uriString = '$baseUrl$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      final qs = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      uriString += (uriString.contains('?') ? '&' : '?') + qs;
    }
    final uri = Uri.parse(uriString);

    HttpClientRequest req;
    switch (method.toUpperCase()) {
      case 'GET':
        req = await client.getUrl(uri);
        break;
      case 'POST':
        req = await client.postUrl(uri);
        break;
      case 'PUT':
        req = await client.putUrl(uri);
        break;
      case 'PATCH':
        req = await client.patchUrl(uri);
        break;
      case 'DELETE':
        req = await client.deleteUrl(uri);
        break;
      default:
        throw Exception('Unsupported method $method');
    }

    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (headers != null) {
      headers.forEach((k, v) => req.headers.set(k, v));
    }
    if (body != null) {
      req.write(jsonEncode(body));
    }

    final res = await req.close();
    final contentType = res.headers.contentType?.mimeType ?? '';
    if (contentType.contains('application/pdf') || contentType.contains('text/csv')) {
      final bytes = await res.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
      return {
        'statusCode': res.statusCode,
        'headers': res.headers,
        'bytes': bytes,
      };
    }

    final resBody = await res.transform(utf8.decoder).join();
    dynamic parsed;
    try {
      parsed = jsonDecode(resBody);
    } catch (_) {
      parsed = resBody;
    }

    return {
      'statusCode': res.statusCode,
      'headers': res.headers,
      'body': parsed,
    };
  }

  group('Group 1: Legal & Public Endpoints', () {
    test('GET /legal/terms returns 200 with terms content', () async {
      final res = await httpReq(method: 'GET', path: '/legal/terms');
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isNotNull);
    });

    test('GET /support/faq returns 200 with FAQ list', () async {
      final res = await httpReq(method: 'GET', path: '/support/faq');
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<List>());
    });

  });

  group('Group 2: Auth Flow (Register, Login, Silent Refresh, OTP)', () {
    test('POST /auth/register creates new user and returns JWT tokens', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/auth/register',
        body: {
          'phoneNumber': testPhone,
          'fullName': 'Nguyen Van Integration',
          'password': 'Password123!',
          'deviceId': 'device-test-fe',
        },
      );
      expect(res['statusCode'], equals(201));
      expect(res['body']['success'], isTrue);
      final data = res['body']['data'];
      expect(data['accessToken'], isNotNull);
      expect(data['refreshToken'], isNotNull);
      expect(data['userId'], isNotNull);

      accessToken = data['accessToken'] as String;
      refreshToken = data['refreshToken'] as String;
      userId = data['userId'] as String;
    });

    test('POST /auth/login authenticates user and updates tokens', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/auth/login',
        body: {
          'phoneNumber': testPhone,
          'password': 'Password123!',
          'deviceId': 'device-test-fe',
        },
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      final data = res['body']['data'];
      expect(data['accessToken'], isNotNull);
      expect(data['refreshToken'], isNotNull);

      accessToken = data['accessToken'] as String;
      refreshToken = data['refreshToken'] as String;
    });

    test('POST /auth/refresh performs silent refresh rotation', () async {
      expect(refreshToken, isNotNull);
      final res = await httpReq(
        method: 'POST',
        path: '/auth/refresh',
        queryParams: {'refreshToken': refreshToken!},
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      final data = res['body']['data'];
      expect(data['accessToken'], isNotNull);
      expect(data['refreshToken'], isNotNull);

      accessToken = data['accessToken'] as String;
      refreshToken = data['refreshToken'] as String;
    });

    test('POST /auth/otp/send sends 6-digit OTP', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/auth/otp/send',
        queryParams: {'phoneNumber': testPhone},
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
    });
  });

  group('Group 3: User Profile, PIN Security & Config Limits', () {
    test('GET /users/me retrieves current user profile', () async {
      final res = await httpReq(method: 'GET', path: '/users/me', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['userId'], equals(userId));
      expect(res['body']['data']['fullName'], equals('Nguyen Van Integration'));
    });

    test('POST /users/pin/set sets 6-digit transaction PIN', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/users/pin/set',
        body: {'pin': '654321'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
    });

    test('POST /users/pin/verify verifies PIN and returns pinToken', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/users/pin/verify',
        body: {'pin': '654321'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      pinToken = res['body']['data'] as String?;
      expect(pinToken, isNotNull);
      expect(pinToken!.isNotEmpty, isTrue);
    });

    test('GET /users/me/qrcode returns personal EMVCo QR code string', () async {
      final res = await httpReq(method: 'GET', path: '/users/me/qrcode', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<String>());
    });

    test('GET /config/limits & status returns user limits', () async {
      final limitsRes = await httpReq(method: 'GET', path: '/config/limits', token: accessToken);
      expect(limitsRes['statusCode'], equals(200));
      expect(limitsRes['body']['success'], isTrue);

      final statusRes = await httpReq(method: 'GET', path: '/config/limits/status', token: accessToken);
      expect(statusRes['statusCode'], equals(200));
      expect(statusRes['body']['success'], isTrue);
      expect(statusRes['body']['data']['dailyLimit'], isNotNull);
    });
  });

  group('Group 4: Wallet Operations & Deposit', () {
    test('GET /wallets/recipient-info resolves user wallet ID', () async {
      final res = await httpReq(
        method: 'GET',
        path: '/wallets/recipient-info',
        queryParams: {'phoneNumber': testPhone},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      walletId = res['body']['data']['walletId'] as String?;
      expect(walletId, isNotNull);
    });

    test('GET /wallets/{walletId} fetches wallet balance and currency', () async {
      expect(walletId, isNotNull);
      final res = await httpReq(method: 'GET', path: '/wallets/$walletId', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['currency'], equals('VND'));
    });

    test('POST /wallets/deposit deposits money into wallet', () async {
      expect(walletId, isNotNull);
      final res = await httpReq(
        method: 'POST',
        path: '/wallets/deposit',
        headers: {'Idempotency-Key': 'dep-test-$timestamp'},
        body: {
          'requestId': 'req-dep-$timestamp',
          'walletId': walletId,
          'amount': 3000000.0,
          'currency': 'VND',
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
    });

    test('GET /wallets/fees/estimate calculates fee for internal transfer', () async {
      final res = await httpReq(
        method: 'GET',
        path: '/wallets/fees/estimate',
        queryParams: {'type': 'TRANSFER', 'amount': '500000', 'currency': 'VND'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['feeAmount'], equals(0));
    });
  });

  group('Group 5: P2P Money Transfer Flow', () {
    test('Set up receiver user for transfer', () async {
      final regRes = await httpReq(
        method: 'POST',
        path: '/auth/register',
        body: {
          'phoneNumber': receiverPhone,
          'fullName': 'Tran Thi Nguoi Nhan',
          'password': 'Password123!',
          'deviceId': 'receiver-device-fe',
        },
      );
      expect(regRes['statusCode'], equals(201));
      final recInfo = await httpReq(
        method: 'GET',
        path: '/wallets/recipient-info',
        queryParams: {'phoneNumber': receiverPhone},
        token: accessToken,
      );
      expect(recInfo['statusCode'], equals(200));
      receiverWalletId = recInfo['body']['data']['walletId'] as String?;
      expect(receiverWalletId, isNotNull);
    });

    test('POST /wallets/transfer/init initiates transfer with PENDING_CONFIRMATION', () async {
      expect(walletId, isNotNull);
      expect(receiverWalletId, isNotNull);

      final res = await httpReq(
        method: 'POST',
        path: '/wallets/transfer/init',
        headers: {'Idempotency-Key': 'init-tx-$timestamp'},
        body: {
          'requestId': 'req-tx-$timestamp',
          'sourceWalletId': walletId,
          'targetWalletId': receiverWalletId,
          'amount': 150000.0,
          'currency': 'VND',
          'bankCode': 'SENHONG',
          'note': 'Test chuyen tien tu dong flutter',
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      final data = res['body']['data'];
      expect(data['status'], equals('PENDING_CONFIRMATION'));
      transferTxId = data['transactionId'] as String?;
      expect(transferTxId, isNotNull);
    });

    test('POST /wallets/transfer/{id}/confirm confirms transfer with PIN', () async {
      expect(transferTxId, isNotNull);
      final res = await httpReq(
        method: 'POST',
        path: '/wallets/transfer/$transferTxId/confirm',
        queryParams: {'pin': '654321'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      final data = res['body']['data'];
      expect(data['status'], equals('SUCCESS'));
      expect(data['balance'], isNotNull);
    });
  });

  group('Group 6: Transaction History, Detail & Statements', () {
    test('GET /transactions retrieves transaction list', () async {
      expect(walletId, isNotNull);
      final res = await httpReq(
        method: 'GET',
        path: '/transactions',
        queryParams: {'walletId': walletId!, 'page': '0', 'size': '10'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<List>());
      expect((res['body']['data'] as List).isNotEmpty, isTrue);
    });

    test('GET /transactions/{id} retrieves single transaction detail', () async {
      expect(transferTxId, isNotNull);
      final res = await httpReq(
        method: 'GET',
        path: '/transactions/$transferTxId',
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['transactionId'], equals(transferTxId));
    });

    test('GET /transactions/{id}/receipt.pdf streams binary PDF receipt', () async {
      expect(transferTxId, isNotNull);
      final res = await httpReq(
        method: 'GET',
        path: '/transactions/$transferTxId/receipt.pdf',
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      final bytes = res['bytes'] as List<int>?;
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(100));
      // Verify PDF magic header "%PDF"
      final magic = String.fromCharCodes(bytes.take(4));
      expect(magic, equals('%PDF'));
    });

    test('GET /transactions/export/csv exports statement in CSV format', () async {
      expect(walletId, isNotNull);
      final res = await httpReq(
        method: 'GET',
        path: '/transactions/export/csv',
        queryParams: {'walletId': walletId!},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      final bytes = res['bytes'] as List<int>?;
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });
  });

  group('Group 7: Banking, Linked Accounts & Beneficiaries', () {
    test('GET /banks returns partner banks list', () async {
      final res = await httpReq(method: 'GET', path: '/banks', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<List>());
      expect((res['body']['data'] as List).length, greaterThanOrEqualTo(4));
    });

    test('POST /bank-accounts/link links bank account', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/bank-accounts/link',
        body: {
          'bankCode': 'VCB',
          'accountNumber': '001100998877',
          'accountHolderName': 'NGUYEN VAN INTEGRATION',
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(201));
      expect(res['body']['success'], isTrue);
      linkedBankAccountId = res['body']['data']['id'] as String?;
      expect(linkedBankAccountId, isNotNull);
    });

    test('GET /bank-accounts lists linked bank accounts', () async {
      final res = await httpReq(method: 'GET', path: '/bank-accounts', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<List>());
      expect((res['body']['data'] as List).isNotEmpty, isTrue);
    });

    test('POST /beneficiaries saves new beneficiary', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/beneficiaries',
        body: {
          'nickname': 'Me Yeu',
          'bankCode': 'SENHONG',
          'accountNumber': receiverPhone,
          'beneficiaryWalletId': receiverWalletId,
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(201));
      expect(res['body']['success'], isTrue);
    });

    test('GET /beneficiaries lists beneficiaries', () async {
      final res = await httpReq(method: 'GET', path: '/beneficiaries', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isA<List>());
      expect((res['body']['data'] as List).isNotEmpty, isTrue);
    });
  });

  group('Group 8: Withdrawal Flow', () {
    test('POST /wallets/withdraw withdraws funds using pinToken & bankAccount', () async {
      expect(walletId, isNotNull);
      expect(linkedBankAccountId, isNotNull);
      expect(pinToken, isNotNull);

      final res = await httpReq(
        method: 'POST',
        path: '/wallets/withdraw',
        headers: {'Idempotency-Key': 'with-$timestamp'},
        body: {
          'requestId': 'req-with-$timestamp',
          'walletId': walletId,
          'bankAccountId': linkedBankAccountId,
          'amount': 50000.0,
          'currency': 'VND',
          'pinToken': pinToken,
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['status'], equals('SUCCESS'));
    });
  });

  group('Group 9: Payments, Bills & VietQR', () {
    String? generatedQr;

    test('GET /bills/lookup queries bill by customer code', () async {
      final res = await httpReq(
        method: 'GET',
        path: '/bills/lookup',
        queryParams: {'type': 'ELECTRICITY', 'customerCode': 'EVN123456'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isNotNull);
    });

    test('POST /payments/vietqr/generate generates valid VietQR string', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/payments/vietqr/generate',
        body: {
          'bankBin': '970436', // VCB
          'accountNumber': '001100998877',
          'amount': 250000,
          'purpose': 'Thanh toan tien sach',
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      generatedQr = (res['body']['data']['qrCodeString'] ?? res['body']['data']['qrCode']) as String?;
      expect(generatedQr, isNotNull);
      expect(generatedQr!.startsWith('000201'), isTrue);
    });

    test('POST /payments/vietqr/decode decodes VietQR payload accurately', () async {
      expect(generatedQr, isNotNull);
      final res = await httpReq(
        method: 'POST',
        path: '/payments/vietqr/decode',
        queryParams: {'qrString': generatedQr!},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data'], isNotNull);
      expect(res['body']['data']['qrCodeString'], equals(generatedQr));
    });
  });

  group('Group 10: Notifications & Customer Support', () {
    test('GET /notifications returns paginated notification records', () async {
      final res = await httpReq(method: 'GET', path: '/notifications', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['content'], isA<List>());
    });

    test('PATCH /notifications/read-all marks all notifications as read', () async {
      final res = await httpReq(method: 'PATCH', path: '/notifications/read-all', token: accessToken);
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
    });

    test('PUT /notifications/settings updates user notification preferences', () async {
      final res = await httpReq(
        method: 'PUT',
        path: '/notifications/settings',
        queryParams: {'transactionEnabled': 'true', 'promoEnabled': 'false'},
        token: accessToken,
      );
      expect(res['statusCode'], equals(200));
      expect(res['body']['success'], isTrue);
    });

    test('POST /support/tickets submits customer support ticket', () async {
      final res = await httpReq(
        method: 'POST',
        path: '/support/tickets',
        queryParams: {
          'subject': 'Support Inquiry Flutter Test',
          'category': 'GENERAL',
          'initialMessage': 'Can you explain the cashback terms for e-wallet?',
        },
        token: accessToken,
      );
      expect(res['statusCode'], equals(201));
      expect(res['body']['success'], isTrue);
      expect(res['body']['data']['id'], isNotNull);
    });
  });

  group('Group 11: Realtime STOMP WebSocket Protocol', () {
    test('Connects to VPS WebSocket STOMP broker and subscribes to notifications', () async {
      expect(userId, isNotNull);
      expect(accessToken, isNotNull);

      final connectedCompleter = Completer<bool>();
      late final StompClient stompClient;

      stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: (StompFrame frame) {
            final topic = '/topic/users/$userId/notifications';
            stompClient.subscribe(
              destination: topic,
              callback: (StompFrame frame) {},
            );
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.complete(true);
            }
          },
          onWebSocketError: (error) {
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.complete(false);
            }
          },
          onStompError: (frame) {
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.complete(false);
            }
          },
          stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      stompClient.activate();

      final success = await connectedCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );

      expect(success, isTrue, reason: 'STOMP client must connect and subscribe within 10s');
      stompClient.deactivate();
    });
  });
}
