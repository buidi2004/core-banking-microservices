import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../auth_local_datasource.dart';
import 'api_response.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  final AuthLocalDataSource _local;

  AuthRemoteDataSource({Dio? dio, required AuthLocalDataSource local})
      : _dio = dio ?? DioClient().dio,
        _local = local;

  Future<void> login({required String phoneNumber, required String password, required String deviceId}) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'phoneNumber': phoneNumber,
      'password': password,
      'deviceId': deviceId,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    final data = json['data'] as Map<String, dynamic>?;
    if (json['success'] != true || data == null) throw apiException(json);
    await _local.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _local.saveIdentity(userId: data['userId'] as String, phoneNumber: data['phoneNumber'] as String? ?? phoneNumber);
    if (data['fullName'] != null && (data['fullName'] as String).isNotEmpty) {
      await _local.saveFullName(data['fullName'] as String);
    }

    // Bước 1: Sau khi login, lấy walletId và profile fullName
    try {
      final token = data['accessToken'] as String;
      final meRes = await _dio.get(
        ApiConstants.userMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final meJson = Map<String, dynamic>.from(meRes.data as Map);
      final meData = meJson['data'] as Map<String, dynamic>?;
      final fullName = meData?['fullName'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        await _local.saveFullName(fullName);
      }

      final walletRes = await _dio.get(
        ApiConstants.walletMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final walletJson = Map<String, dynamic>.from(walletRes.data as Map);
      final walletData = walletJson['data'] as Map<String, dynamic>?;
      final walletId = walletData?['id'] as String?;
      if (walletId != null && walletId.isNotEmpty) {
        await _local.saveWalletId(walletId);
      }
    } catch (_) {}
  }

  Future<void> register({required String phoneNumber, required String fullName, required String password, required String deviceId}) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'password': password,
      'deviceId': deviceId,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);

    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        await _local.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      }
      final userId = data['userId'] as String?;
      if (userId != null) {
        await _local.saveIdentity(userId: userId, phoneNumber: phoneNumber);
      }
      if (fullName.isNotEmpty) {
        await _local.saveFullName(fullName);
      }

      // Pre-fetch walletId sau khi đăng ký
      try {
        if (accessToken != null) {
          final walletRes = await _dio.get(
            ApiConstants.walletMe,
            options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          );
          final walletJson = Map<String, dynamic>.from(walletRes.data as Map);
          final walletData = walletJson['data'] as Map<String, dynamic>?;
          final walletId = walletData?['id'] as String?;
          if (walletId != null && walletId.isNotEmpty) {
            await _local.saveWalletId(walletId);
          }
        }
      } catch (_) {}
    } else {
      await _local.saveFullName(fullName);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    final response = await _dio.post(ApiConstants.otpSend, queryParameters: {'phoneNumber': phoneNumber});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<bool> verifyOtp({required String phoneNumber, required String otp}) async {
    final response = await _dio.post(ApiConstants.otpVerify, queryParameters: {'phoneNumber': phoneNumber, 'otp': otp});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    return json['data'] == true;
  }

  Future<void> forgotPassword(String phoneNumber) async {
    final response = await _dio.post(ApiConstants.forgotPassword, queryParameters: {'phoneNumber': phoneNumber});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<void> resetPassword({required String phoneNumber, required String otp, required String newPassword}) async {
    final response = await _dio.post(ApiConstants.resetPassword, queryParameters: {
      'phoneNumber': phoneNumber,
      'otp': otp,
      'newPassword': newPassword,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<void> setPin(String pin) async {
    final response = await _dio.post(ApiConstants.setPin, data: {'pin': pin});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }
}