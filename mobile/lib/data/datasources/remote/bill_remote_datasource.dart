import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class BillRemoteDataSource {
  final Dio _dio;

  BillRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<Map<String, dynamic>> lookup({required String type, required String customerCode}) async {
    final response = await _dio.get(
      ApiConstants.billLookup,
      queryParameters: {'type': type, 'customerCode': customerCode},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> pay({
    required String walletId,
    required String billId,
    required double amount,
  }) async {
    final response = await _dio.post(ApiConstants.billPay, data: {
      'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': walletId,
      'billId': billId,
      'amount': amount,
      'currency': 'VND',
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> topup({
    required String walletId,
    required String phoneNumber,
    required double amount,
  }) async {
    final response = await _dio.post(ApiConstants.billTopup, data: {
      'requestId': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': walletId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'currency': 'VND',
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}