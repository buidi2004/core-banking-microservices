import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class SupportRemoteDataSource {
  final Dio _dio;

  SupportRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getFaq() async {
    final response = await _dio.get(ApiConstants.faq);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await _dio.get(ApiConstants.tickets);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String initialMessage,
    String category = 'GENERAL',
  }) async {
    final response = await _dio.post(
      ApiConstants.tickets,
      queryParameters: {
        'subject': subject,
        'category': category,
        'initialMessage': initialMessage,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> getTicketDetail(String ticketId) async {
    final response = await _dio.get('${ApiConstants.tickets}/$ticketId');
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<Map<String, dynamic>> addMessage({
    required String ticketId,
    required String content,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.tickets}/$ticketId/messages',
      queryParameters: {'content': content},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
