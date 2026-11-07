import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class ConfigRemoteDataSource {
  final Dio _dio;

  ConfigRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  /// Lấy bảng hạn mức giao dịch theo phân tầng định danh QĐ 2345/QĐ-NHNN
  Future<Map<String, dynamic>> getLimits() async {
    final response = await _dio.get(ApiConstants.configLimits);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// Lấy hiện trạng hạn mức giao dịch đã sử dụng trong ngày và trong tháng của tài khoản
  Future<Map<String, dynamic>> getLimitStatus() async {
    final response = await _dio.get(ApiConstants.limitStatus);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
