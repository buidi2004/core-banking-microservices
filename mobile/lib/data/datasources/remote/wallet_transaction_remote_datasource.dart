import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class WalletTransactionRemoteDataSource {
  final Dio _dio;

  WalletTransactionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<Map<String, dynamic>> deposit({required String walletId, required double amount}) async {
    final response = await _dio.post(ApiConstants.deposit, data: {
      'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': walletId,
      'amount': amount,
      'currency': 'VND',
    });
    return _unwrap(response.data);
  }

  Future<String> verifyPin(String pin) async {
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