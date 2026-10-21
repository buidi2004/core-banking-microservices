import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

void main() {
  group('PIN & OTP Contract Tests', () {
    late Dio dio;
    late MockHttpClientAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));
      adapter = MockHttpClientAdapter();
      dio.httpClientAdapter = adapter;
    });

    test('AuthRemoteDataSource setPin calls POST /users/pin/set with pin body', () async {
      RequestOptions? captured;
      adapter.handler = (options) {
        captured = options;
        return jsonResponse({'success': true, 'message': 'PIN set successfully'});
      };

      final authRemote = AuthRemoteDataSource(dio: dio);
      await authRemote.setPin('123456');

      expect(captured, isNotNull);
      expect(captured!.path, equals(ApiConstants.setPin));
      expect(captured!.method, equals('POST'));
      expect(captured!.data, equals({'pin': '123456'}));
    });

    test('WalletTransactionRemoteDataSource verifyPin calls POST /users/pin/verify and extracts pinToken from Map', () async {
      RequestOptions? captured;
      adapter.handler = (options) {
        captured = options;
        return jsonResponse({
          'success': true,
          'data': {
            'valid': true,
            'pinToken': 'mock-pin-jwt-token',
          }
        });
      };

      final walletTxRemote = WalletTransactionRemoteDataSource(dio: dio);
      final token = await walletTxRemote.verifyPin('123456');

      expect(captured, isNotNull);
      expect(captured!.path, equals(ApiConstants.verifyPin));
      expect(captured!.method, equals('POST'));
      expect(captured!.data, equals({'pin': '123456'}));
      expect(token, equals('mock-pin-jwt-token'));
    });

    test('AuthRemoteDataSource sendOtp calls POST /auth/otp/send with phoneNumber and purpose', () async {
      RequestOptions? captured;
      adapter.handler = (options) {
        captured = options;
        return jsonResponse({'success': true, 'message': 'OTP sent'});
      };

      final authRemote = AuthRemoteDataSource(dio: dio);
      await authRemote.sendOtp('0901234567', purpose: 'RESET_PASSWORD');

      expect(captured, isNotNull);
      expect(captured!.path, equals(ApiConstants.otpSend));
      expect(captured!.method, equals('POST'));
      expect(captured!.data, equals({
        'phoneNumber': '0901234567',
        'purpose': 'RESET_PASSWORD',
      }));
    });

    test('AuthRemoteDataSource verifyOtp calls POST /auth/otp/verify and returns true on valid OTP', () async {
      RequestOptions? captured;
      adapter.handler = (options) {
        captured = options;
        return jsonResponse({
          'success': true,
          'data': {
            'valid': true,
            'verified': true,
          }
        });
      };

      final authRemote = AuthRemoteDataSource(dio: dio);
      final ok = await authRemote.verifyOtp(phoneNumber: '0901234567', otp: '654321', purpose: 'RESET_PIN');

      expect(captured, isNotNull);
      expect(captured!.path, equals(ApiConstants.otpVerify));
      expect(captured!.method, equals('POST'));
      expect(captured!.data, equals({
        'phoneNumber': '0901234567',
        'code': '654321',
        'purpose': 'RESET_PIN',
      }));
      expect(ok, isTrue);
    });

    test('AuthRemoteDataSource verifyOtpFull returns detailed map including tempToken', () async {
      adapter.handler = (options) {
        return jsonResponse({
          'success': true,
          'data': {
            'valid': true,
            'tempToken': 'reset-token-xyz',
          }
        });
      };

      final authRemote = AuthRemoteDataSource(dio: dio);
      final res = await authRemote.verifyOtpFull(phoneNumber: '0901234567', otp: '654321');

      expect(res['valid'], isTrue);
      expect(res['tempToken'], equals('reset-token-xyz'));
    });

    test('TransferRemoteDataSource attaches pinToken in body and X-Pin-Token header', () async {
      RequestOptions? captured;
      adapter.handler = (options) {
        captured = options;
        return jsonResponse({
          'success': true,
          'data': {
            'transactionId': 'tx-12345',
            'status': 'SUCCESS',
            'amount': 50000,
          }
        });
      };

      final transferRemote = TransferRemoteDataSource(dio: dio);
      final result = await transferRemote.initTransfer(
        sourceUserId: 'user-source-01',
        targetUserId: 'user-target-02',
        amount: 50000,
        note: 'Chuyen tien an trua',
        pinToken: 'mock-pin-jwt-token',
      );

      expect(captured, isNotNull);
      expect(captured!.path, equals(ApiConstants.paymentTransfer));
      expect(captured!.method, equals('POST'));
      expect(captured!.headers['X-Pin-Token'], equals('mock-pin-jwt-token'));
      final reqBody = captured!.data as Map<String, dynamic>;
      expect(reqBody['pinToken'], equals('mock-pin-jwt-token'));
      expect(reqBody['amount'], equals(50000));
      expect(result['transactionId'], equals('tx-12345'));
    });
  });
}

