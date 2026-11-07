import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';

void main() {
  const samplePemPublicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzyHR+zayzca2BUUyx+O
ByAq9NGEqidBjZGX0NNf4cRW9im+SRffnkLB+Iku8zZnvoCIMCCEjVYawIJS2XRK
bqbQCAKCbE1Q/lITdEaDaPDvaCd5Mr8aIsKY9LewTFKy57JdAvSdvoSOidNMn4R6
y86oA9F+YHHj2L1KtskhpV4uZFwhUfjsA/wQOgZgMXzcGu/xD7jh9m9K0PswRwPq
l9PIozREDnN8sCLnUllE3E/jf05TI++94E+DrAd0GRljhIzufWI+3F97z9OWAPh6
YLvBXJ00qIERcfgVcqtrpKBK2K7bYM5PEoyJMMjccxSya2ZEtt+2KYPSr6s3AtG/
wQIDAQAB
-----END PUBLIC KEY-----''';

  group('eKYC SDK - Cryptography & Models', () {
    test('PemUtils parses RSA 2048-bit Public Key correctly', () {
      final pubKey = PemUtils.parseRsaPublicKey(samplePemPublicKey);
      expect(pubKey, isNotNull);
      expect(pubKey.modulus, isNotNull);
      expect(pubKey.exponent, isNotNull);
      expect(pubKey.modulus!.bitLength, inInclusiveRange(2040, 2048));
    });

    test('HybridCryptoClient generates valid AES-256-GCM + RSA-OAEP envelope', () {
      final pubKey = PemUtils.parseRsaPublicKey(samplePemPublicKey);
      final crypto = HybridCryptoClient(serverPublicKey: pubKey);

      final envelope = crypto.encryptPayload(
        sessionId: 'test-session-12345',
        nonce: 'test-nonce-abcdef',
        payload: {
          'selfie': 'base64-selfie-data',
          'chipPhoto': 'base64-chip-data',
          'documentNumber': '001202000001',
        },
      );

      expect(envelope['sessionId'], equals('test-session-12345'));
      expect(envelope['nonce'], equals('test-nonce-abcdef'));
      expect(envelope['wrappedKey'], isNotEmpty);
      expect(envelope['nonceB64'], isNotEmpty);
      expect(envelope['ciphertext'], isNotEmpty);

      // Verify base64 decodability
      final wrappedBytes = base64Decode(envelope['wrappedKey'] as String);
      final gcmNonceBytes = base64Decode(envelope['nonceB64'] as String);
      final cipherBytes = base64Decode(envelope['ciphertext'] as String);

      expect(wrappedBytes.length, equals(256)); // RSA 2048-bit wrapped key = 256 bytes
      expect(gcmNonceBytes.length, equals(12)); // AES-GCM nonce = 12 bytes
      expect(cipherBytes.length, greaterThan(16)); // Ciphertext includes 16-byte GCM tag
    });

    test('EkycSession and EkycVerificationResult parse JSON faithfully', () {
      final sessionJson = {
        'sessionId': 'sess-001',
        'nonce': 'nonce-001',
        'ttlSeconds': 240,
        'cryptoScheme': 'RSA-OAEP-SHA256 + AES-256-GCM',
      };
      final session = EkycSession.fromJson(sessionJson);
      expect(session.sessionId, equals('sess-001'));
      expect(session.nonce, equals('nonce-001'));
      expect(session.ttlSeconds, equals(240));

      final verifyJson = {
        'sessionId': 'sess-001',
        'decision': 'APPROVED',
        'liveness': {'is_live': true, 'score': 0.985},
        'faceMatch': {'matched': true, 'similarity': 0.892},
        'latencyMs': 45,
      };
      final result = EkycVerificationResult.fromJson(verifyJson);
      expect(result.sessionId, equals('sess-001'));
      expect(result.decision, equals(EkycDecision.approved));
      expect(result.isLive, isTrue);
      expect(result.isMatched, isTrue);
      expect(result.livenessScore, closeTo(0.985, 0.001));
      expect(result.similarity, closeTo(0.892, 0.001));
    });

    test('ActiveLivenessDetector tracks challenges progress', () {
      final detector = ActiveLivenessDetector(customChallenges: [
        LivenessChallenge.blink,
        LivenessChallenge.turnLeft,
      ]);

      expect(detector.currentChallenge, equals(LivenessChallenge.blink));
      expect(detector.currentStepNumber, equals(1));
      expect(detector.totalSteps, equals(2));
      expect(detector.isCompleted, isFalse);
    });
  });
}
