import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class LegalRemoteDataSource {
  final Dio _dio;

  LegalRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<String> getTerms() async {
    final response = await _dio.get(ApiConstants.legalTerms);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] == null) throw apiException(json);
    return json['data'].toString();
  }

  Future<Map<String, dynamic>> consent(String termsVersion) async {
    final response = await _dio.post(
      ApiConstants.legalConsent,
      queryParameters: {'termsVersion': termsVersion},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
