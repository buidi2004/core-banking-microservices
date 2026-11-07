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

  /// Lấy danh sách các hóa đơn đã đăng ký ủy thác trích nợ tự động (Auto-Debit Subscriptions)
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    final response = await _dio.get(ApiConstants.billSubscriptions);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Đăng ký mới ủy thác trích nợ tự động hóa đơn
  Future<Map<String, dynamic>> createSubscription({
    required String billType,
    required String customerCode,
    required String providerCode,
    String? walletId,
    int autoDebitDay = 5,
  }) async {
    final response = await _dio.post(
      ApiConstants.billSubscriptions,
      data: {
        if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
        'billType': billType,
        'customerCode': customerCode,
        'providerCode': providerCode,
        'autoDebitDay': autoDebitDay,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// Hủy ủy thác trích nợ tự động hóa đơn
  Future<void> cancelSubscription(String subscriptionId) async {
    final response = await _dio.delete(ApiConstants.billSubscriptionDetail(subscriptionId));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }
}