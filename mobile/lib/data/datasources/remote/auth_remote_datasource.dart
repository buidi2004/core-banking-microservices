import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/push_notification_service.dart';
import '../auth_local_datasource.dart';
import 'api_response.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  final AuthLocalDataSource? _local;

  AuthRemoteDataSource({Dio? dio, AuthLocalDataSource? local})
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
    final String? accessToken = data['accessToken'] as String? ?? data['token'] as String?;
    final String? refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) throw apiException(json);
    await _local?.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _local?.saveIdentity(userId: data['userId'] as String, phoneNumber: data['phoneNumber'] as String? ?? phoneNumber);
    if (data['fullName'] != null && (data['fullName'] as String).isNotEmpty) {
      await _local?.saveFullName(data['fullName'] as String);
    }

    // Bước 1: Sau khi login, lấy walletId và profile fullName
    try {
      final token = accessToken;
      final meRes = await _dio.get(
        ApiConstants.userMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final meJson = Map<String, dynamic>.from(meRes.data as Map);
      final meData = meJson['data'] as Map<String, dynamic>?;
      final fullName = meData?['fullName'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        await _local?.saveFullName(fullName);
      }

      final walletRes = await _dio.get(
        ApiConstants.walletMe,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final walletJson = Map<String, dynamic>.from(walletRes.data as Map);
      final walletData = walletJson['data'] as Map<String, dynamic>?;
      final walletId = walletData?['id'] as String?;
      if (walletId != null && walletId.isNotEmpty) {
        await _local?.saveWalletId(walletId);
      }
    } catch (_) {}
  }

  Future<void> register({
    required String phoneNumber,
    required String fullName,
    required String password,
    required String deviceId,
    String? email,
  }) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'password': password,
      'deviceId': deviceId,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);

    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      final accessToken = (data['accessToken'] ?? data['token']) as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null && refreshToken != null) {
        await _local?.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      }
      final userId = data['userId'] as String?;
      if (userId != null) {
        await _local?.saveIdentity(userId: userId, phoneNumber: phoneNumber);
      }
      if (fullName.isNotEmpty) {
        await _local?.saveFullName(fullName);
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
            await _local?.saveWalletId(walletId);
          }
        }
      } catch (_) {}
    } else {
      await _local?.saveFullName(fullName);
    }
  }

  Future<void> refreshToken() async {
    final currentRefresh = await _local?.getRefreshToken();
    if (currentRefresh == null || currentRefresh.isEmpty) {
      throw Exception('No refresh token available');
    }
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refreshToken': currentRefresh},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    final data = json['data'] as Map<String, dynamic>?;
    if (json['success'] != true || data == null) throw apiException(json);
    final String? accessToken = data['accessToken'] as String? ?? data['token'] as String?;
    final String? refreshToken = data['refreshToken'] as String?;
    if (accessToken == null) throw apiException(json);
    await _local?.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken ?? currentRefresh,
    );
  }

  Future<void> logout({String? deviceId}) async {
    try {
      // 1. Unregister FCM token với backend TRƯỚC khi token bị blacklist
      try {
        await PushNotificationService().unregisterDeviceFromBackend();
      } catch (e) {
        debugPrint('[AuthRemoteDataSource] Unregister FCM error: $e');
      }

      // 2. Gọi API logout backend để blacklist access token trong Redis
      final token = await _local?.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await _dio.post(
          ApiConstants.logout,
          queryParameters: {
            if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      debugPrint('[AuthRemoteDataSource] Logout network/backend error: $e');
    } finally {
      // 3. Luôn luôn xóa token và thông tin cục bộ
      await _local?.clearTokens();
    }
  }

  Future<void> sendOtp(String phoneNumber, {String? purpose, String? email}) async {
    final response = await _dio.post(ApiConstants.otpSend, data: {
      'phoneNumber': phoneNumber,
      if (purpose != null) 'purpose': purpose,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  /// Yêu cầu gửi mã OTP tới Gmail chính chủ (định danh qua X-User-Id do Gateway inject).
  /// Trả về thông tin đã che mờ (maskedEmail) để UI hiển thị cho người dùng.
  Future<Map<String, dynamic>> requestChangePasswordOtp() async {
    final response = await _dio.post(ApiConstants.changePasswordOtp);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map? ?? {});
  }

  /// Đổi mật khẩu đăng nhập: yêu cầu OTP (otpToken) đã xác thực qua Gmail.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    String otp = '',
  }) async {
    final response = await _dio.post(
      ApiConstants.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'otp': otp,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<bool> verifyOtp({required String phoneNumber, required String otp, String? purpose}) async {
    final data = await verifyOtpFull(phoneNumber: phoneNumber, otp: otp, purpose: purpose);
    return data['verified'] == true || data.isNotEmpty;
  }

  Future<Map<String, dynamic>> verifyOtpFull({
    required String phoneNumber,
    required String otp,
    String? purpose,
  }) async {
    final response = await _dio.post(ApiConstants.otpVerify, data: {
      'phoneNumber': phoneNumber,
      'code': otp,
      if (purpose != null) 'purpose': purpose,
    });
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map? ?? {});
  }

  Future<void> forgotPassword(String phoneNumber) async {
    final response = await _dio.post(ApiConstants.forgotPassword, data: {'phoneNumber': phoneNumber});
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
  }

  Future<void> resetPassword({required String phoneNumber, required String otp, required String newPassword}) async {
    final response = await _dio.post(ApiConstants.resetPassword, data: {
      'phoneNumber': phoneNumber,
      'otpToken': otp,
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