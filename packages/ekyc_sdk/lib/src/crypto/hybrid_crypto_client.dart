import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class HybridCryptoClient {
  final RSAPublicKey serverPublicKey;

  HybridCryptoClient({required this.serverPublicKey});

  /// Mã hóa lai chuẩn quân sự/ngân hàng:
  /// 1. Sinh khóa AES-256 + nonce GCM 12-byte ngẫu nhiên cryptographically secure.
  /// 2. Mã hóa JSON payload bằng AES-256-GCM với AAD = "ekyc-session:{sessionId}".
  /// 3. Bọc (wrap) khóa AES bằng RSA-OAEP-SHA256 sử dụng public key của Server.
  Map<String, dynamic> encryptPayload({
    required String sessionId,
    required String nonce,
    required Map<String, dynamic> payload,
  }) {
    // 1. Sinh ngẫu nhiên 32 bytes AES key và 12 bytes GCM nonce
    final aesKey = _secureRandomBytes(32);
    final gcmNonce = _secureRandomBytes(12);

    // 2. Mã hóa AES-256-GCM
    final aad = utf8.encode('ekyc-session:$sessionId');
    final plaintext = utf8.encode(jsonEncode(payload));

    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true, // mode encrypt
        AEADParameters(
          KeyParameter(aesKey),
          128, // 16 bytes MAC/tag
          gcmNonce,
          Uint8List.fromList(aad),
        ),
      );

    final ciphertextWithTag = gcm.process(Uint8List.fromList(plaintext));

    // 3. Wrap AES key bằng RSA-OAEP-SHA256
    final rsaCipher = OAEPEncoding.withCustomDigest(
      () => SHA256Digest(),
      RSAEngine(),
    )..init(true, PublicKeyParameter<RSAPublicKey>(serverPublicKey));

    final wrappedKey = rsaCipher.process(aesKey);

    return {
      'sessionId': sessionId,
      'nonce': nonce,
      'wrappedKey': base64Encode(wrappedKey),
      'nonceB64': base64Encode(gcmNonce),
      'ciphertext': base64Encode(ciphertextWithTag),
    };
  }

  static Uint8List _secureRandomBytes(int count) {
    final rnd = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(count, (_) => rnd.nextInt(256)));
  }
}
