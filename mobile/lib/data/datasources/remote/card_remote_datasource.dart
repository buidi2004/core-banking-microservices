import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class CardRemoteDataSource {
  final Dio _dio;

  CardRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getCards() async {
    final response = await _dio.get(ApiConstants.cards);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> issueCard({
    required String type,
    bool physical = false,
    String? deliveryAddress,
  }) async {
    final response = await _dio.post(
      ApiConstants.cardIssue,
      data: {
        'type': type,
        'physical': physical,
        'deliveryAddress': deliveryAddress,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> updateStatus(String cardId, String status) async {
    final response = await _dio.patch(
      ApiConstants.cardStatus(cardId),
      data: {'status': status},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> updateSettings(
    String cardId, {
    bool? onlinePayment,
    bool? intlPayment,
    bool? contactless,
    bool? atmWithdraw,
  }) async {
    final response = await _dio.put(
      ApiConstants.cardSettings(cardId),
      data: {
        if (onlinePayment != null) 'onlinePayment': onlinePayment,
        if (intlPayment != null) 'intlPayment': intlPayment,
        if (contactless != null) 'contactless': contactless,
        if (atmWithdraw != null) 'atmWithdraw': atmWithdraw,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}

