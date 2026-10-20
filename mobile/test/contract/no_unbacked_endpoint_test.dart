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

    test('verifyPin KHÔNG phát HTTP khi transactionPin=false', () async {
      expect(BackendCapabilities.transactionPin, isFalse);

      await expectLater(
        walletTx.verifyPin('123456'),
        throwsA(isA<UnsupportedError>()),
      );

      expect(mockAdapter.calls, isEmpty,
          reason: 'Không được phát bất kỳ HTTP request nào tới endpoint BE-GAP.');
    });

    test('deposit KHÔNG phát HTTP khi deposit=false', () async {
      expect(BackendCapabilities.deposit, isFalse);

      await expectLater(
        walletTx.deposit(walletId: 'w-1', amount: 10000),
        throwsA(isA<UnsupportedError>()),
      );

      expect(mockAdapter.calls, isEmpty);
    });

    test('withdraw KHÔNG phát HTTP khi withdraw=false', () async {
      expect(BackendCapabilities.withdraw, isFalse);

      await expectLater(
        walletTx.withdraw(
          walletId: 'w-1',
          bankAccountId: 'b-1',
          amount: 10000,
          pinToken: 'token',
        ),
        throwsA(isA<UnsupportedError>()),
      );

      expect(mockAdapter.calls, isEmpty);
    });

    test('confirmTransfer/initTransfer bị chặn hoàn toàn khi serverSideTransferAuth=false', () async {
      expect(BackendCapabilities.serverSideTransferAuth, isFalse);

      final transfer = TransferRemoteDataSource(dio: dio);

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
          reason: 'Không được giả lập giao dịch chuyển tiền thành công khi backend chưa hỗ trợ xác thực.');
    });

    test('mọi hằng route BE-GAP đều nằm trong knownBackendGaps', () {
      final gapConstants = <String>[
        ApiConstants.otpVerify,
        ApiConstants.otpSend,
        ApiConstants.setPin,
        ApiConstants.verifyPin,
        ApiConstants.deposit,
        ApiConstants.withdraw,
        ApiConstants.receiptPdf('x'),
        ApiConstants.exportTransactions('csv'),
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
        ApiConstants.limitStatus,
        ApiConstants.configLimits,
      ];

      for (final path in gapConstants) {
        expect(
          BackendCapabilities.hasEndpoint(path),
          isFalse,
          reason: 'Route "$path" chưa có ở backend baseline nhưng chưa được đánh dấu BE-GAP.',
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
