import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class MoneyRequestRemoteDataSource {
  final Dio _dio;

  MoneyRequestRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getReceived() async {
    final response = await _dio.get(ApiConstants.moneyRequestsReceived);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getSent() async {
    final response = await _dio.get(ApiConstants.moneyRequestsSent);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    final response = await _dio.get(ApiConstants.moneyRequestDetail(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> create({
    required String payerUserId,
    required double amount,
    String currency = 'VND',
    String? message,
  }) async {
    final response = await _dio.post(
      ApiConstants.moneyRequests,
      data: {
        'payerUserId': payerUserId,
        'amount': amount,
        'currency': currency,
        if (message != null) 'message': message,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> accept(String id) async {
    final response = await _dio.post(ApiConstants.moneyRequestAccept(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> reject(String id) async {
    final response = await _dio.post(ApiConstants.moneyRequestReject(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    final response = await _dio.post(ApiConstants.moneyRequestCancel(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
