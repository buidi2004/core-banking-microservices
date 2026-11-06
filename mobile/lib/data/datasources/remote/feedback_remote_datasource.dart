import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class FeedbackRemoteDataSource {
  final Dio _dio;

  FeedbackRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<Map<String, dynamic>> submit({
    required String content,
    String? category,
    int? rating,
  }) async {
    final response = await _dio.post(
      ApiConstants.feedback,
      data: {
        'content': content,
        if (category != null) 'category': category,
        if (rating != null) 'rating': rating,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}

