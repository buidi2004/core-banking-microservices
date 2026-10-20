import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class FundingSourceRemoteDataSource {
  final Dio _dio;
  FundingSourceRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get(ApiConstants.fundingSources);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> link(Map<String, dynamic> payload) async {
    final response = await _dio.post('${ApiConstants.fundingSources}/link', data: payload);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<void> remove(String id) async {
    final response = await _dio.delete('${ApiConstants.fundingSources}/$id');
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }
}