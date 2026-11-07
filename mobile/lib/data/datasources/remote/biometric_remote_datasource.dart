import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class BiometricRemoteDataSource {
  final Dio _dio;

  BiometricRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  /// Xác thực sinh trắc học khuôn mặt/vân tay với Identity Service
  /// Trả về pinToken/biometricToken có thẩm quyền ký số giao dịch theo QĐ 2345/QĐ-NHNN
  Future<Map<String, dynamic>> verify({Map<String, dynamic>? metadata}) async {
    final response = await _dio.post(
      ApiConstants.biometricVerify,
      data: metadata ?? {},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
