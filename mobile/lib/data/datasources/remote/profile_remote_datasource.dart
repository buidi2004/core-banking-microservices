import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_secure_storage.dart';
import 'api_response.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ProfileRemoteDataSource({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? DioClient().dio,
        _storage = storage ?? AppSecureStorage.instance;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiConstants.userMe);
    final map = _map(response.data);

    // Backend /users/me không trả về trường phoneNumber.
    // Lấy phoneNumber từ secure storage hoặc payload của JWT access token.
    if (map['phoneNumber'] == null || (map['phoneNumber'] as String).isEmpty) {
      final savedPhone = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyPhoneNumber);
      if (savedPhone != null && savedPhone.isNotEmpty) {
        map['phoneNumber'] = savedPhone;
      } else {
        final token = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAccessToken);
        if (token != null && token.isNotEmpty) {
          final phoneFromJwt = _extractPhoneFromJwt(token);
          if (phoneFromJwt != null && phoneFromJwt.isNotEmpty) {
            map['phoneNumber'] = phoneFromJwt;
            await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyPhoneNumber, value: phoneFromJwt);
          }
        }
      }
    }

    final fullName = map['fullName'] as String?;
    if (fullName != null && fullName.isNotEmpty) {
      await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyFullName, value: fullName);
    }

    final avatarUrl = map['avatarUrl'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAvatarUrl, value: avatarUrl);
    }
    return map;
  }

  String? _extractPhoneFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final normalized = base64Url.normalize(parts[1]);
        final payload = utf8.decode(base64Url.decode(normalized));
        final json = jsonDecode(payload) as Map<String, dynamic>;
        return json['phone'] as String? ?? json['phoneNumber'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Cập nhật profile: PUT /users/profile với body JSON {'fullName', 'email', 'dateOfBirth'}
  /// - Nếu dob rỗng → không gửi field dateOfBirth (BE không chấp nhận field rỗng)
  /// - Nếu avatarUrl là URL http(s) → PUT /users/profile {'avatarUrl': url}
  /// - Nếu avatarUrl là base64 → không gọi API, trả lỗi "Backend chưa hỗ trợ upload ảnh"
  Future<Map<String, dynamic>> updateMe({
    required String fullName,
    required String email,
    required String dob,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName,
      'email': email,
    };
    if (dob.isNotEmpty) {
      body['dateOfBirth'] = dob;
    }
    if (avatarUrl != null && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      body['avatarUrl'] = avatarUrl;
    }

    final response = await _dio.put(ApiConstants.userProfile, data: body);
    return _map(response.data);
  }

  /// Cập nhật avatar: BE không có /users/me/avatar.
  /// - Nếu avatarUrl là URL http(s) → PUT /users/profile {'avatarUrl': url}
  /// - Nếu avatarUrl là base64 (mobile đang gửi) → không gọi API, trả thông báo "Backend chưa hỗ trợ upload ảnh"
  /// - Giữ ảnh local
  Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      try {
        final response = await _dio.put(
          ApiConstants.userProfile,
          data: {'avatarUrl': avatarUrl},
        );
        final map = _map(response.data);
        await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAvatarUrl, value: avatarUrl);
        return map;
      } catch (e) {
        await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAvatarUrl, value: avatarUrl);
        return {};
      }
    }

    // Nếu avatarUrl là base64 → BACKEND CHƯA HỖ TRỢ UPLOAD ẢNH
    // Không gọi API, trả thông báo nghiệp vụ và lưu ảnh local
    await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAvatarUrl, value: avatarUrl);
    return {'message': 'Backend chưa hỗ trợ upload ảnh'};
  }

  Future<String?> getCachedAvatar() async {
    return await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAvatarUrl);
  }

  Future<Map<String, dynamic>?> getKycStatus() async {
    final response = await _dio.get(ApiConstants.kycStatus);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    if (json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>> submitKyc(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.kycSubmit, data: payload);
    return _map(response.data);
  }

  Map<String, dynamic> _map(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}