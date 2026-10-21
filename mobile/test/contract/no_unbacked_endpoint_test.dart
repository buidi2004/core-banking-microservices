import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';

/// =============================================================================
/// REGRESSION TEST — "KHÔNG GỌI ENDPOINT CHƯA CÓ BACKEND"  (MOB-007 / R2-P1-02)
/// =============================================================================
/// Mục tiêu: chứng minh rằng **không đường nào** trong mobile phát HTTP tới
/// endpoint mà backend baseline (`75bf273`) chưa có, và **không màn hình nào**
/// báo "thành công" giả.
///
/// Dùng `MockHttpClientAdapter` đếm số request thực sự phát ra.
/// -----------------------------------------------------------------------------

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

void main() {
  group('No-unbacked-endpoint regression (MOB-007)', () {
    late Dio dio;
    late MockHttpClientAdapter mockAdapter;
    late WalletTransactionRemoteDataSource walletTx;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      mockAdapter = MockHttpClientAdapter();
      mockAdapter.handler = (_) => jsonResponse({'success': true, 'data': {}});
      dio.httpClientAdapter = mockAdapter;
      walletTx = WalletTransactionRemoteDataSource(dio: dio);
    });

    test('verifyPin gọi POST /users/pin/verify khi transactionPin=true', () async {
      expect(BackendCapabilities.transactionPin, isTrue);
      mockAdapter.handler = (_) => jsonResponse({
            'success': true,
            'data': {'pinToken': 'pin-token-1'},
          });

      final token = await walletTx.verifyPin('123456');

      expect(token, equals('pin-token-1'));
      expect(mockAdapter.calls, hasLength(1));
      expect(mockAdapter.calls.single.path, equals(ApiConstants.verifyPin));
    });

    test('deposit gọi POST /wallets/deposit khi deposit=true', () async {
      expect(BackendCapabilities.deposit, isTrue);
      mockAdapter.handler = (_) => jsonResponse({
            'success': true,
            'data': {'transactionId': 'tx-deposit-1'},
          });

      final res = await walletTx.deposit(walletId: 'w-1', amount: 10000);

      expect(res['transactionId'], equals('tx-deposit-1'));
      expect(mockAdapter.calls, hasLength(1));
      expect(mockAdapter.calls.single.path, equals(ApiConstants.deposit));
    });

    test('withdraw gọi POST /wallets/withdraw khi withdraw=true', () async {
      expect(BackendCapabilities.withdraw, isTrue);
      mockAdapter.handler = (_) => jsonResponse({
            'success': true,
            'data': {'transactionId': 'tx-withdraw-1'},
          });

      final res = await walletTx.withdraw(
        walletId: 'w-1',
        bankAccountId: 'b-1',
        amount: 10000,
        pinToken: 'token',
      );

      expect(res['transactionId'], equals('tx-withdraw-1'));
      expect(mockAdapter.calls, hasLength(1));
      expect(mockAdapter.calls.single.path, equals(ApiConstants.withdraw));
    });

    test('initTransfer bị chặn hoàn toàn khi serverSideTransferAuth=false', () async {
      final transfer =
          TransferRemoteDataSource(dio: dio, serverSideTransferAuth: false);

      await expectLater(
        transfer.initTransfer(
          sourceUserId: 'u-1',
          targetUserId: 'u-2',
          amount: 50000,
          note: 'regression',
        ),
        throwsA(isA<UnsupportedError>()),
      );

      expect(mockAdapter.calls, isEmpty,
          reason: 'Không được giả lập giao dịch chuyển tiền khi tắt xác thực server-side.');
    });

    test('chỉ các hằng route thực sự chưa tích hợp mới nằm trong knownBackendGaps', () {
      final gapConstants = <String>[
        ApiConstants.receiptPdf('x'),
        ApiConstants.exportTransactions('csv'),
        ApiConstants.limitStatus,
        ApiConstants.configLimits,
      ];

      for (final path in gapConstants) {
        expect(
          BackendCapabilities.hasEndpoint(path),
          isFalse,
          reason: 'Route "$path" chưa tích hợp nhưng chưa được đánh dấu BE-GAP.',
        );
      }

      final implementedConstants = <String>[
        ApiConstants.otpVerify,
        ApiConstants.otpSend,
        ApiConstants.setPin,
        ApiConstants.verifyPin,
        ApiConstants.deposit,
        ApiConstants.withdraw,
        ApiConstants.decodeVietQr,
        ApiConstants.generateVietQr,
        ApiConstants.billLookup,
        ApiConstants.billPay,
        ApiConstants.billTopup,
        ApiConstants.beneficiaries,
        ApiConstants.fundingSources,
        ApiConstants.bankAccounts,
        ApiConstants.bankAccountsLink,
        ApiConstants.bankAccountDetail('x'),
      ];

      for (final path in implementedConstants) {
        expect(
          BackendCapabilities.hasEndpoint(path),
          isTrue,
          reason: 'Route "$path" đã có ở backend nhưng vẫn bị chặn nhầm.',
        );
      }
    });

    test('route có thật ở backend không bị chặn nhầm', () {
      final realRoutes = <String>[
        ApiConstants.login,
        ApiConstants.refresh,
        ApiConstants.logout,
        ApiConstants.userProfile,
        ApiConstants.paymentTransfer,
        ApiConstants.walletMe,
        ApiConstants.transactions,
        ApiConstants.moneyRequests,
        ApiConstants.promotions,
        ApiConstants.deviceRegister,
        ApiConstants.deviceUnregister,
      ];

      for (final path in realRoutes) {
        expect(
          BackendCapabilities.hasEndpoint(path),
          isTrue,
          reason: 'Route "$path" có thật ở backend baseline — không được chặn nhầm.',
        );
      }
    });
  });
}
