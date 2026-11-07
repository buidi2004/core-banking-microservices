import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/ekyc_models.dart';

class ActiveLivenessDetector {
  final List<LivenessChallenge> challenges;
  int _currentStepIndex = 0;
  bool _isCompleted = false;

  ActiveLivenessDetector({List<LivenessChallenge>? customChallenges})
      : challenges = customChallenges ?? _generateRandomChallenges();

  static List<LivenessChallenge> _generateRandomChallenges() {
    final list = [
      LivenessChallenge.blink,
      Random().nextBool()
          ? LivenessChallenge.turnLeft
          : LivenessChallenge.turnRight,
      LivenessChallenge.smile,
    ];
    return list;
  }

  LivenessChallenge? get currentChallenge =>
      _isCompleted || _currentStepIndex >= challenges.length
          ? null
          : challenges[_currentStepIndex];

  int get currentStepNumber => _currentStepIndex + 1;
  int get totalSteps => challenges.length;
  bool get isCompleted => _isCompleted;
  double get progress => _currentStepIndex / challenges.length;

  /// Phân tích frame từ ML Kit Face Detector
  bool processFace(Face face) {
    if (_isCompleted) return true;

    final challenge = currentChallenge;
    if (challenge == null) {
      _isCompleted = true;
      return true;
    }

    bool stepPassed = false;
    switch (challenge) {
      case LivenessChallenge.blink:
        final leftOpen = face.leftEyeOpenProbability ?? 1.0;
        final rightOpen = face.rightEyeOpenProbability ?? 1.0;
        // Cả 2 mắt nhắm hoặc chớp rõ rệt
        if (leftOpen < 0.25 && rightOpen < 0.25) {
          stepPassed = true;
        }
        break;

      case LivenessChallenge.turnLeft:
        final yaw = face.headEulerAngleY ?? 0.0;
        // Camera selfie (front-facing): Khi người dùng quay đầu sang trái,
        // góc yaw trên ML Kit mang giá trị âm (< -18 độ).
        if (yaw < -18.0) {
          stepPassed = true;
        }
        break;

      case LivenessChallenge.turnRight:
        final yaw = face.headEulerAngleY ?? 0.0;
        // Khi người dùng quay đầu sang phải trên camera selfie,
        // góc yaw trên ML Kit mang giá trị dương (> +18 độ).
        if (yaw > 18.0) {
          stepPassed = true;
        }
        break;

      case LivenessChallenge.smile:
        final smileProb = face.smilingProbability ?? 0.0;
        if (smileProb > 0.65) {
          stepPassed = true;
        }
        break;
    }

    if (stepPassed) {
      _currentStepIndex++;
      if (_currentStepIndex >= challenges.length) {
        _isCompleted = true;
      }
      return true;
    }

    return false;
  }

  /// Kiểm tra xem khuôn mặt có nằm cân đối trong khung Oval hướng dẫn hay không
  bool isFaceInsideOval({
    required Face face,
    required double previewWidth,
    required double previewHeight,
  }) {
    final box = face.boundingBox;
    final faceCenterX = box.left + box.width / 2.0;
    final faceCenterY = box.top + box.height / 2.0;

    final centerX = previewWidth / 2.0;
    final centerY = previewHeight / 2.0;

    final diffX = (faceCenterX - centerX).abs();
    final diffY = (faceCenterY - centerY).abs();

    // Dung sai cho phép lệch tâm tối đa 18% kích thước màn hình
    final inCenter =
        diffX < (previewWidth * 0.18) && diffY < (previewHeight * 0.18);
    final validSize =
        box.width > (previewWidth * 0.35) && box.width < (previewWidth * 0.85);

    return inCenter && validSize;
  }

  void reset() {
    _currentStepIndex = 0;
    _isCompleted = false;
  }
}
