import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class PromotionRemoteDataSource {
  final Dio _dio;

  PromotionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getPromotions() async {
    final response = await _dio.get(ApiConstants.promotions);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMyVouchers() async {
    final response = await _dio.get(ApiConstants.myVouchers);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> apply({required String code, required double orderAmount}) async {
    final response = await _dio.post(
      ApiConstants.applyPromotion,
      queryParameters: {'code': code, 'orderAmount': orderAmount},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> redeem(String code) async {
    final response = await _dio.post(
      ApiConstants.redeemPromotion,
      queryParameters: {'code': code},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
