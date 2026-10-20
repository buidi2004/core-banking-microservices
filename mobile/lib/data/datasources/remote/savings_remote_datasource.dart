import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class SavingsRemoteDataSource {
  final Dio _dio;

  SavingsRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _dio.get(ApiConstants.savingsProducts);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> openSavings({
    required String walletId,
    required String productType,
    required int termMonths,
    required double depositAmount,
    String? rolloverType,
    String? pinToken,
  }) async {
    final response = await _dio.post(
      ApiConstants.savingsAccounts,
      data: {
        'walletId': walletId,
        'productType': productType,
        'termMonths': termMonths,
        'depositAmount': depositAmount,
        'rolloverType': rolloverType ?? 'AUTO_ROLLOVER_ALL',
        if (pinToken != null && pinToken.isNotEmpty) 'pinToken': pinToken,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getUserSavings() async {
    final response = await _dio.get(ApiConstants.savingsAccounts);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getSavingsDetail(String id) async {
    final response = await _dio.get(ApiConstants.savingsDetail(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> settleSavings(String id, {String? pinToken}) async {
    final response = await _dio.post(
      ApiConstants.savingsSettle(id),
      data: {
        if (pinToken != null && pinToken.isNotEmpty) 'pinToken': pinToken,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}

