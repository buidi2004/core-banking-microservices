import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import '../crypto/hybrid_crypto_client.dart';
import '../crypto/pem_utils.dart';
import '../models/ekyc_models.dart';

class EkycApiClient {
  final String baseUrl;
  final RSAPublicKey serverPublicKey;
  final http.Client _httpClient;

  EkycApiClient({
    required this.baseUrl,
    required this.serverPublicKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  factory EkycApiClient.withPemKey({
    required String baseUrl,
    required String pemPublicKey,
    http.Client? httpClient,
  }) {
    final pubKey = PemUtils.parseRsaPublicKey(pemPublicKey);
    return EkycApiClient(
      baseUrl: baseUrl,
      serverPublicKey: pubKey,
      httpClient: httpClient,
    );
  }

  /// Kiểm tra trạng thái GPU/Model/Redis của eKYC Microservice
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('$baseUrl/api/v1/ekyc/ai/health');
    final response = await _httpClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('eKYC Service Healthcheck failed: ${response.statusCode}');
  }

  /// Khởi tạo phiên eKYC bảo mật với TTL 240s và nonce dùng một lần
  Future<EkycSession> createSession(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/ekyc/ai/session');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return EkycSession.fromJson(data);
    }
    throw Exception(
        'Tạo phiên eKYC thất bại [${response.statusCode}]: ${response.body}');
  }

  /// Xác thực sinh trắc học với mã hóa lai AES-256-GCM + RSA-OAEP
  Future<EkycVerificationResult> verifyBiometrics({
    required EkycSession session,
    required Uint8List selfieBytes,
    required Uint8List chipPhotoBytes,
    String? documentNumber,
  }) async {
    final cryptoClient = HybridCryptoClient(serverPublicKey: serverPublicKey);

    final innerPayload = {
      'selfie': base64Encode(selfieBytes),
      'chipPhoto': base64Encode(chipPhotoBytes),
      if (documentNumber != null) 'documentNumber': documentNumber,
    };

    final encryptedEnvelope = cryptoClient.encryptPayload(
      sessionId: session.sessionId,
      nonce: session.nonce,
      payload: innerPayload,
    );

    final uri = Uri.parse('$baseUrl/api/v1/ekyc/ai/verify');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(encryptedEnvelope),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return EkycVerificationResult.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Phát hiện Replay Attack hoặc phiên eKYC đã hết hạn');
    }
    throw Exception(
        'Xác thực eKYC thất bại [${response.statusCode}]: ${response.body}');
  }

  void close() {
    _httpClient.close();
  }
}
