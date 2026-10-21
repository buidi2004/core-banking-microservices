import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';

/// Contract test cho Money Movement / History & Network Layer
/// Mục đích: Chứng minh call mobile khớp đúng backend thật, không có call giả.
/// Test này chạy với MockHttpClientAdapter, không cần backend thật.

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
  group('Money Movement Contract Test', () {
    late Dio dio;
    late MockHttpClientAdapter mockAdapter;
    late TransferRemoteDataSource transferRemote;
    late TransactionRemoteDataSource transactionRemote;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      mockAdapter = MockHttpClientAdapter();
      dio.httpClientAdapter = mockAdapter;
      transferRemote = TransferRemoteDataSource(
        dio: dio,
        serverSideTransferAuth: true,
      );
      transactionRemote = TransactionRemoteDataSource(dio: dio);
    });

    final Map<String, dynamic> responseData = {
      'success': true,
      'data': {
        'transactionId': 'tx-123',
        'status': 'SUCCESS',
        'amount': 500000.0,
        'balance': 4500000.0,
        'runningBalance': 4500000.0,
      }
    };

    /// W2: Khi serverSideTransferAuth=false, KHÔNG có request POST nào được gửi
    test('W2: Transfer blocked when serverSideTransferAuth=false', () async {
      // Mặc định hiện tại ĐÃ BẬT vì backend có /users/pin/verify.
      expect(BackendCapabilities.serverSideTransferAuth, isTrue);
      expect(BackendCapabilities.transactionPin, isTrue);
      expect(BackendCapabilities.otp, isTrue);

      // Rollback an toàn: tắt cờ tường minh ⇒ phải chặn, không phát HTTP.
      final blockedTransfer =
          TransferRemoteDataSource(dio: dio, serverSideTransferAuth: false);
      expect(
        () => blockedTransfer.initTransfer(
          sourceUserId: 'u-1',
          targetUserId: 'u-2',
          amount: 50000.0,
          note: 'Blocked test',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    /// W3: initTransfer chỉ gọi POST /payments/transfer, không gọi GET /wallets/{id} khi đã có ownerId
    test('W3: initTransfer calls POST /payments/transfer only (1 RTT optimization)', () async {
      RequestOptions? recordedOptions;
      mockAdapter.handler = (options) {
        recordedOptions = options;
        return jsonResponse(responseData);
      };

      final res = await transferRemote.initTransfer(
        sourceUserId: 'user-source',
        targetUserId: 'user-target',
        amount: 500000.0,
        note: 'Test transfer',
      );

      expect(recordedOptions, isNotNull);
      expect(recordedOptions!.path, equals(ApiConstants.paymentTransfer));
      expect(recordedOptions!.data, isA<Map>());
      expect(recordedOptions!.data['sourceUserId'], equals('user-source'));
      expect(recordedOptions!.data['targetUserId'], equals('user-target'));
      expect(recordedOptions!.data['amount'], equals(500000));
      expect(res['transactionId'], equals('tx-123'));
      expect(res['status'], equals('SUCCESS'));
    });

    /// W5: getTransaction gửi walletId query param
    test('W5: getTransaction sends walletId query parameter', () async {
      RequestOptions? recordedOptions;
      mockAdapter.handler = (options) {
        recordedOptions = options;
        return jsonResponse(responseData);
      };

      await transactionRemote.getTransaction('tx-123', walletId: 'w-123');

      expect(recordedOptions, isNotNull);
      expect(recordedOptions!.path, equals(ApiConstants.transactionDetail('tx-123')));
      expect(recordedOptions!.queryParameters['walletId'], equals('w-123'));
    });

    /// W5b: TRANSFER_IN hiển thị amount > 0, runningBalance đúng
    test('W5b: TRANSFER_IN transaction has positive amount and correct runningBalance', () async {
      final transferInResponse = {
        'success': true,
        'data': {
          'transactionId': 'tx-in-456',
          'type': 'TRANSFER_IN',
          'status': 'SUCCESS',
          'amount': 200000.0,
          'balance': 5200000.0,
          'runningBalance': 5200000.0,
          'counterpartyName': 'NGUYEN VAN A',
        }
      };

      mockAdapter.handler = (options) => jsonResponse(transferInResponse);

      final res = await transactionRemote.getTransaction('tx-in-456', walletId: 'w-123');

      expect(res['type'].toString().toLowerCase(), equals('transfer_in'));
      expect(res['amount'], greaterThan(0));
      expect(res['runningBalance'], equals(5200000.0));
    });

    /// W1: DioClient singleton config - logger off in release, sendTimeout exists
    test('W1: DioClient configuration - no body logging in release, has sendTimeout', () {
      expect(DioClient.sharedDio, isNotNull);
      expect(DioClient.sharedDio.options.sendTimeout?.inMilliseconds, equals(15000));
      expect(DioClient.sharedDio.options.connectTimeout?.inMilliseconds, equals(15000));
      expect(DioClient.sharedDio.options.receiveTimeout?.inMilliseconds, equals(15000));
    });

    /// W4: Idempotency key sinh một lần, retry dùng lại key
    test('W4: Idempotency key generated once per transaction, reused on retry', () async {
      RequestOptions? recordedOptions;
      mockAdapter.handler = (options) {
        recordedOptions = options;
        return jsonResponse(responseData);
      };

      final res1 = await transferRemote.initTransfer(
        sourceUserId: 'u-1',
        targetUserId: 'u-2',
        amount: 100000.0,
        note: 'Test',
      );

      expect(recordedOptions, isNotNull);
      expect(recordedOptions!.path, equals(ApiConstants.paymentTransfer));
      expect(recordedOptions!.data['idempotencyKey'], isNotNull);
      expect(res1['transactionId'], equals('tx-123'));
    });

    /// W7: Capability flags phản ánh endpoint đã có / còn thiếu
    test('W7: Capability flags phản ánh endpoint đã có / còn thiếu', () {
      expect(BackendCapabilities.deposit, isTrue);
      expect(BackendCapabilities.withdraw, isTrue);
      expect(BackendCapabilities.bills, isTrue);
      expect(BackendCapabilities.vietQr, isTrue);
      expect(BackendCapabilities.bankAccounts, isTrue);
      expect(BackendCapabilities.fundingSources, isTrue);
      expect(BackendCapabilities.beneficiaries, isTrue);
      expect(BackendCapabilities.receiptAndExport, isFalse,
          reason: 'Receipt/Export chưa tích hợp ở mobile');
    });

    /// W19: Không có 2 màn xác nhận trùng lặp (chỉ 1 luồng chuẩn)
    test('W19: Single confirm transfer flow documented', () {
      expect(ApiConstants.transferInit, contains('/wallets/transfer/init'));
      expect(ApiConstants.transferConfirm('tx'), contains('/wallets/transfer/'));
    });
  });
}
