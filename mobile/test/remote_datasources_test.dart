import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/device_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;
  String? userId;
  String? phoneNumber;
  String? fullName;
  bool hideBalance = false;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> saveIdentity({required String userId, required String phoneNumber}) async {
    this.userId = userId;
    this.phoneNumber = phoneNumber;
  }

  @override
  Future<void> saveFullName(String fullName) async {
    this.fullName = fullName;
  }

  @override
  Future<String?> getFullName() async => fullName;

  String? walletId;

  @override
  Future<void> saveWalletId(String walletId) async {
    this.walletId = walletId;
  }

  @override
  Future<String?> getWalletId() async => walletId;

  @override
  Future<void> setHideBalance(bool hide) async => hideBalance = hide;

  @override
  Future<bool> getHideBalance() async => hideBalance;
}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _map = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) {
      final key = invocation.namedArguments[#key] as String;
      return Future.value(_map[key]);
    }
    if (invocation.memberName == #write) {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value != null) _map[key] = value;
      return Future.value();
    }
    if (invocation.memberName == #delete) {
      final key = invocation.namedArguments[#key] as String;
      _map.remove(key);
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late Dio dio;
  late MockHttpClientAdapter mockAdapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://mock-api.com/api/v1'));
    mockAdapter = MockHttpClientAdapter();
    dio.httpClientAdapter = mockAdapter;
  });

  group('AuthRemoteDataSource Tests (Real Backend Contract)', () {
    test('login success saves tokens and identity', () async {
      final fakeLocal = FakeAuthLocalDataSource();
      final authDs = AuthRemoteDataSource(dio: dio, local: fakeLocal);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.login));
        expect(options.data, isA<Map>());
        expect(options.data['phoneNumber'], equals('0987654321'));
        expect(options.data['password'], equals('password'));
        expect(options.data['deviceId'], equals('dev-1'));
        return jsonResponse({
          'success': true,
          'message': 'Login successful',
          'data': {
            'userId': 'u-123',
            'phoneNumber': '0987654321',
            'accessToken': 'token-abc',
            'refreshToken': 'refresh-xyz',
          },
        });
      };

      await authDs.login(phoneNumber: '0987654321', password: 'password', deviceId: 'dev-1');
      expect(fakeLocal.accessToken, equals('token-abc'));
      expect(fakeLocal.refreshToken, equals('refresh-xyz'));
      expect(fakeLocal.userId, equals('u-123'));
      expect(fakeLocal.phoneNumber, equals('0987654321'));
    });

    test('login error throws exception with error message', () async {
      final fakeLocal = FakeAuthLocalDataSource();
      final authDs = AuthRemoteDataSource(dio: dio, local: fakeLocal);

      mockAdapter.handler = (options) {
        return jsonResponse({
          'success': false,
          'message': 'Sai mật khẩu',
          'errorCode': 'INVALID_PIN',
        }, statusCode: 400);
      };

      expect(
        () => authDs.login(phoneNumber: '0987654321', password: 'wrong', deviceId: 'dev-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('refresh token sends JSON body (not query params) per BE contract', () async {
      final fakeLocal = FakeAuthLocalDataSource();
      fakeLocal.refreshToken = 'refresh-xyz';
      final authDs = AuthRemoteDataSource(dio: dio, local: fakeLocal);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.refresh));
        // BE expects JSON body with refreshToken
        expect(options.data, isA<Map>());
        expect(options.data['refreshToken'], equals('refresh-xyz'));
        expect(options.queryParameters, isEmpty);
        return jsonResponse({
          'success': true,
          'data': {
            'accessToken': 'new-token-abc',
            'refreshToken': 'new-refresh-xyz',
          },
        });
      };

      await authDs.refreshToken();
      expect(fakeLocal.accessToken, equals('new-token-abc'));
      expect(fakeLocal.refreshToken, equals('new-refresh-xyz'));
    });
  });

  group('WalletRemoteDataSource Tests (Real Backend Contract)', () {
    test('getMyWallet fallback to recipient-info and wallet detail', () async {
      final fakeStorage = FakeSecureStorage();
      await fakeStorage.write(key: AppConstants.keyPhoneNumber, value: '0987654321');

      final walletDs = WalletRemoteDataSource(dio: dio, storage: fakeStorage);

      mockAdapter.handler = (options) {
        if (options.path == ApiConstants.walletMe) {
          return jsonResponse({'success': false, 'message': 'Not found'}, statusCode: 404);
        } else if (options.path == ApiConstants.recipientInfo) {
          return jsonResponse({
            'success': true,
            'data': {'walletId': 'w-999', 'phoneNumber': '0987654321'},
          });
        } else if (options.path == ApiConstants.walletDetail('w-999')) {
          return jsonResponse({
            'success': true,
            'data': {
              'id': 'w-999',
              'ownerId': 'u-123',
              'balance': 1500000.0,
              'currency': 'VND',
            },
          });
        }
        throw Exception('Unexpected path ${options.path}');
      };

      final wallet = await walletDs.getMyWallet();
      expect(wallet.walletId, equals('w-999'));
      expect(wallet.userId, equals('u-123'));
      expect(wallet.balance, equals(1500000.0));
      expect(wallet.currency, equals('VND'));

      // Check cached walletId in storage
      expect(await fakeStorage.read(key: AppConstants.keyWalletId), equals('w-999'));
    });
  });

  group('TransferRemoteDataSource Tests (Real Backend Contract)', () {
    test('getRecipient by phoneNumber and walletId', () async {
      final transferDs = TransferRemoteDataSource(dio: dio);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.recipientInfo));
        return jsonResponse({
          'success': true,
          'data': {
            'walletId': 'w-recip',
            'phoneNumber': '0912345678',
            'maskedName': 'NGUYEN V** B',
            'fullName': 'Nguyen Van B',
          },
        });
      };

      final recip = await transferDs.getRecipient('0912345678');
      expect(recip['walletId'], equals('w-recip'));
      expect(recip['maskedName'], equals('NGUYEN V** B'));
    });

    test('estimateFee returns estimated feeAmount', () async {
      final transferDs = TransferRemoteDataSource(dio: dio);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.estimateFee));
        return jsonResponse({
          'success': true,
          'data': {'feeAmount': 5500.0},
        });
      };

      final fee = await transferDs.estimateFee(1000000);
      expect(fee, equals(5500.0));
    });

    test('initTransfer calls POST /payments/transfer (single-step, not init/confirm)', () async {
      // REAL BACKEND CONTRACT: POST /payments/transfer is a single-step transfer
      // Old mobile code used /wallets/transfer/init + /confirm which DON'T EXIST in backend
      final transferDs = TransferRemoteDataSource(dio: dio, serverSideTransferAuth: true);

      mockAdapter.handler = (options) {
        // Should call the REAL endpoint
        expect(options.path, equals(ApiConstants.paymentTransfer));
        expect(options.data, isA<Map>());
        // Backend expects sourceUserId, targetUserId, amount, etc.
        expect(options.data['sourceUserId'], isNotNull);
        expect(options.data['targetUserId'], isNotNull);
        expect(options.data['amount'], equals(500000));
        return jsonResponse({
          'success': true,
          'data': {
            'transactionId': 'tx-real-1',
            'status': 'SUCCESS',
            'amount': 500000.0,
            'balance': 4500000.0,
          },
        });
      };

      final res = await transferDs.initTransfer(
        sourceUserId: 'u-1',
        targetUserId: 'u-2',
        sourceWalletId: 'w-1',
        targetWalletId: 'w-2',
        amount: 500000.0,
        note: 'Tra tien an',
      );
      expect(res['transactionId'], equals('tx-real-1'));
      expect(res['status'], equals('SUCCESS'));
    });

    test('confirmTransfer không phát HTTP và trả lại kết quả saga đã chạy ở init', () async {
      final transferDs =
          TransferRemoteDataSource(dio: dio, serverSideTransferAuth: true);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.paymentTransfer));
        return jsonResponse({
          'success': true,
          'data': {
            'transactionId': 'tx-saga-1',
            'status': 'SUCCESS',
            'amount': 500000.0,
          },
        });
      };

      await transferDs.initTransfer(
        sourceUserId: 'u-1',
        targetUserId: 'u-2',
        amount: 500000.0,
        note: 'Saga một bước',
      );

      final confirm = await transferDs.confirmTransfer(transactionId: 'tx-saga-1');

      expect(confirm['transactionId'], equals('tx-saga-1'));
      expect(confirm['status'], equals('SUCCESS'));
      expect(mockAdapter.calls, hasLength(1),
          reason: 'confirmTransfer không được phát thêm HTTP request nào.');
    });

    test('confirmTransfer ném lỗi thay vì giả lập thành công khi thiếu kết quả saga', () async {
      final transferDs = TransferRemoteDataSource(dio: dio);

      await expectLater(
        transferDs.confirmTransfer(transactionId: 'tx-khong-ton-tai', pin: '123456'),
        throwsA(isA<StateError>()),
      );
      expect(mockAdapter.calls, isEmpty);
    });
  });

  group('WalletTransactionRemoteDataSource Tests (Real Backend Contract)', () {
    test('deposit calls POST /wallets/deposit', () async {
      final txDs = WalletTransactionRemoteDataSource(dio: dio);
      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.deposit));
        expect(options.data['walletId'], equals('w-1'));
        expect(options.data['amount'], equals(1000000.0));
        return jsonResponse({
          'success': true,
          'data': {'transactionId': 'tx-d-1'},
        });
      };

      final res = await txDs.deposit(walletId: 'w-1', amount: 1000000.0);
      expect(res['transactionId'], equals('tx-d-1'));
    });

    test('verifyPin calls POST /users/pin/verify and returns pinToken', () async {
      final txDs = WalletTransactionRemoteDataSource(dio: dio);
      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.verifyPin));
        expect(options.data['pin'], equals('654321'));
        return jsonResponse({
          'success': true,
          'data': {'pinToken': 'pin-token-1'},
        });
      };

      final token = await txDs.verifyPin('654321');
      expect(token, equals('pin-token-1'));
    });

    test('withdraw calls POST /wallets/withdraw with pinToken', () async {
      final txDs = WalletTransactionRemoteDataSource(dio: dio);
      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.withdraw));
        expect(options.data['pinToken'], equals('sample-pin-token-12345'));
        return jsonResponse({
          'success': true,
          'data': {'transactionId': 'tx-w-1'},
        });
      };

      final res = await txDs.withdraw(
        walletId: 'w-1',
        bankAccountId: 'ba-1',
        amount: 50000.0,
        pinToken: 'sample-pin-token-12345',
      );
      expect(res['transactionId'], equals('tx-w-1'));
    });
  });

  group('BankAccountRemoteDataSource Tests (BE-GAP Endpoints)', () {
    test('getAccounts - BE-GAP: endpoint does not exist in backend', () async {
      final bankDs = BankAccountRemoteDataSource(dio: dio);

      mockAdapter.handler = (options) {
        expect(options.path, equals(ApiConstants.bankAccounts));
        return jsonResponse({
          'success': false,
          'message': 'Not Found',
        }, statusCode: 404);
      };

      expect(() => bankDs.getAccounts(), throwsA(isA<Exception>()));
    });
  });

  group('DeviceRemoteDataSource Tests (Real Backend Contract)', () {
    test('registerDevice and unregisterDevice succeed', () async {
      final deviceDs = DeviceRemoteDataSource(dio: dio);

      mockAdapter.handler = (options) {
        if (options.path == ApiConstants.deviceRegister) {
          expect(options.method, equals('POST'));
          return jsonResponse({'success': true, 'data': {'fcmToken': 'token-123'}});
        } else if (options.path == ApiConstants.deviceUnregister) {
          expect(options.method, equals('DELETE'));
          return jsonResponse({'success': true, 'data': null});
        }
        throw Exception('Unexpected path');
      };

      await expectLater(
        deviceDs.registerDevice(fcmToken: 'token-123', deviceType: 'ANDROID'),
        completes,
      );
      await expectLater(
        deviceDs.unregisterDevice('token-123'),
        completes,
      );
    });
  });
}