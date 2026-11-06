import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class LotteryRemoteDataSource {
  final Dio _dio;

  LotteryRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<Map<String, dynamic>> buyTicket({
    required String gameName,
    required List<int> numbers,
    int quantity = 1,
    String? drawPeriod,
    String? pinToken,
  }) async {
    final response = await _dio.post(
      ApiConstants.lotteryBuy,
      data: {
        'gameName': gameName,
        'numbers': numbers,
        'quantity': quantity,
        if (drawPeriod != null) 'drawPeriod': drawPeriod,
        if (pinToken != null) 'pinToken': pinToken,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final response = await _dio.get(ApiConstants.lotteryMyTickets);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final response = await _dio.get(ApiConstants.lotteryResults);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

