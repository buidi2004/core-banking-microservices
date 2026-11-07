import 'dart:typed_data';

enum LivenessChallenge {
  blink('Vui lòng nháy mắt tự nhiên'),
  turnLeft('Nghiêng đầu nhẹ sang trái'),
  turnRight('Nghiêng đầu nhẹ sang phải'),
  smile('Vui lòng mỉm cười nhẹ');

  final String instruction;
  const LivenessChallenge(this.instruction);
}

enum EkycDecision {
  approved,
  rejected,
  manualReview;

  static EkycDecision fromString(String val) {
    switch (val.toUpperCase()) {
      case 'APPROVED':
        return EkycDecision.approved;
      case 'MANUAL_REVIEW':
        return EkycDecision.manualReview;
      default:
        return EkycDecision.rejected;
    }
  }
}

class EkycSession {
  final String sessionId;
  final String nonce;
  final int ttlSeconds;
  final String cryptoScheme;

  const EkycSession({
    required this.sessionId,
    required this.nonce,
    required this.ttlSeconds,
    required this.cryptoScheme,
  });

  factory EkycSession.fromJson(Map<String, dynamic> json) {
    return EkycSession(
      sessionId: json['sessionId'] as String,
      nonce: json['nonce'] as String,
      ttlSeconds: json['ttlSeconds'] as int? ?? 240,
      cryptoScheme:
          json['cryptoScheme'] as String? ?? 'RSA-OAEP-SHA256 + AES-256-GCM',
    );
  }
}

class EkycVerificationResult {
  final String sessionId;
  final EkycDecision decision;
  final double? livenessScore;
  final double? similarity;
  final bool isLive;
  final bool isMatched;
  final int latencyMs;
  final String? reason;
  final String? errorCode;
  final String? errorMessage;
  final String? retryStep; // 'SELFIE', 'CHIP', 'NONE'

  const EkycVerificationResult({
    required this.sessionId,
    required this.decision,
    this.livenessScore,
    this.similarity,
    required this.isLive,
    required this.isMatched,
    required this.latencyMs,
    this.reason,
    this.errorCode,
    this.errorMessage,
    this.retryStep,
  });

  factory EkycVerificationResult.fromJson(Map<String, dynamic> json) {
    final liveness = json['liveness'] as Map<String, dynamic>? ?? {};
    final faceMatch = json['faceMatch'] as Map<String, dynamic>? ?? {};
    final decisionStr = json['decision'] as String? ?? 'REJECTED';

    return EkycVerificationResult(
      sessionId: json['sessionId'] as String? ?? '',
      decision: EkycDecision.fromString(decisionStr),
      livenessScore: (liveness['score'] as num?)?.toDouble(),
      similarity: (faceMatch['similarity'] as num?)?.toDouble(),
      isLive: liveness['is_live'] as bool? ?? false,
      isMatched: faceMatch['matched'] as bool? ?? false,
      latencyMs: json['latencyMs'] as int? ?? 0,
      reason: faceMatch['reason'] as String?,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      retryStep: json['retryStep'] as String?,
    );
  }
}

class CccdChipData {
  final String documentNumber;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String expiryDate;
  final Uint8List? facePhotoBytes;
  final bool sodSignatureValid;

  const CccdChipData({
    required this.documentNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.expiryDate,
    this.facePhotoBytes,
    required this.sodSignatureValid,
  });
}

class BACKey {
  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiry;

  const BACKey(this.documentNumber, this.dateOfBirth, this.dateOfExpiry);
}
