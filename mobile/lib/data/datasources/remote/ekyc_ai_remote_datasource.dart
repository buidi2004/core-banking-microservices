import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_secure_storage.dart';

/// DataSource kết nối tới Sen Hồng eKYC AI Microservice qua API Gateway.
/// Tích hợp toàn diện bộ SDK ekyc_sdk:
/// - Mã hóa lai AES-256-GCM + RSA-OAEP-SHA256
/// - Chống Replay Attack bằng nonce sử dụng 1 lần (Redis TTL 240s)
/// - Xác thực Passive Liveness (MiniFASNetV2) & So khớp khuôn mặt (ArcFace 512-d)
class EkycAiRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final HybridCryptoClient _cryptoClient;

  EkycAiRemoteDataSource({
    Dio? dio,
    FlutterSecureStorage? storage,
    String? serverPublicKeyPem,
  })  : _dio = dio ?? DioClient().dio,
        _storage = storage ?? AppSecureStorage.instance,
        _cryptoClient = HybridCryptoClient(
          serverPublicKey: PemUtils.parseRsaPublicKey(
            serverPublicKeyPem ?? ApiConstants.ekycServerPublicKeyPem,
          ),
        );

  /// Kiểm tra trạng thái AI Pipeline (GPU/ONNX Runtime & Redis Session)
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _dio.get(ApiConstants.ekycAiHealth);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Khởi tạo phiên eKYC bảo mật với Redis TTL 240 giây
  Future<EkycSession> createSession({String? userId}) async {
    String? uid = userId;
    if (uid == null || uid.isEmpty) {
      uid = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyUserId);
    }
    uid ??= 'anonymous-user';

    final response = await _dio.post(
      ApiConstants.ekycAiSession,
      data: {'userId': uid},
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return EkycSession.fromJson(data);
  }

  /// Gửi dữ liệu sinh trắc học đã mã hóa lai (AES-256-GCM + RSA-OAEP)
  Future<EkycVerificationResult> verifyBiometrics({
    required EkycSession session,
    required Uint8List selfieBytes,
    required Uint8List chipPhotoBytes,
    String? documentNumber,
  }) async {
    final innerPayload = {
      'selfie': base64Encode(selfieBytes),
      'chipPhoto': base64Encode(chipPhotoBytes),
      if (documentNumber != null && documentNumber.isNotEmpty)
        'documentNumber': documentNumber,
    };

    final encryptedEnvelope = _cryptoClient.encryptPayload(
      sessionId: session.sessionId,
      nonce: session.nonce,
      payload: innerPayload,
    );

    final response = await _dio.post(
      ApiConstants.ekycAiVerify,
      data: encryptedEnvelope,
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return EkycVerificationResult.fromJson(data);
  }
}
