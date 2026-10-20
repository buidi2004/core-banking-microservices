import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/backend_capabilities.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

/// Datasource cho các thao tác biến động số dư của ví.
///
/// MOB-007: BE chưa cung cấp các endpoint deposit/withdraw/PIN user-level
/// (BE-REQ-06 / BE-REQ-03) => mọi mutation đều bị chặn tại đây, không gọi 404.
class WalletTransactionRemoteDataSource {
  final Dio _dio;

  WalletTransactionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.sharedDio;

  Future<Map<String, dynamic>> deposit({required String walletId, required double amount}) async {
    if (!BackendCapabilities.deposit) {
      throw UnsupportedError(
        'Backend chưa cung cấp API nạp tiền user-level (BE-REQ-06).',
      );
    }
    final response = await _dio.post(ApiConstants.deposit, data: {
      'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': walletId,
      'amount': amount,
      'currency': 'VND',
    });
    return _unwrap(response.data);
  }

  Future<String> verifyPin(String pin) async {
    if (!BackendCapabilities.transactionPin) {
      throw UnsupportedError(
        'Backend chưa cung cấp API xác thực PIN (BE-REQ-03).',
      );
    }
    final response = await _dio.post(ApiConstants.verifyPin, data: {'pin': pin});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! String) throw apiException(json);
    return json['data'] as String;
  }

  Future<Map<String, dynamic>> withdraw({
    required String walletId,
    required String bankAccountId,
    required double amount,
    required String pinToken,
  }) async {
    if (!BackendCapabilities.withdraw) {
      throw UnsupportedError(
        'Backend chưa cung cấp API rút tiền user-level (BE-REQ-06).',
      );
    }
    final response = await _dio.post(ApiConstants.withdraw, data: {
      'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': walletId,
      'bankAccountId': bankAccountId,
      'amount': amount,
      'currency': 'VND',
      'pinToken': pinToken,
    });
    return _unwrap(response.data);
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
