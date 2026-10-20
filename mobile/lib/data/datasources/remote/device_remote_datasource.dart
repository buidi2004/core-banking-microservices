import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class DeviceRemoteDataSource {
  final Dio _dio;

  DeviceRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<void> registerDevice({
    required String fcmToken,
    required String deviceType, // "ANDROID" | "IOS"
  }) async {
    final response = await _dio.post(
      ApiConstants.deviceRegister,
      data: {
        'fcmToken': fcmToken,
        'deviceType': deviceType,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<void> unregisterDevice(String fcmToken) async {
    final response = await _dio.delete(
      ApiConstants.deviceUnregister,
      queryParameters: {'fcmToken': fcmToken},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }
}
