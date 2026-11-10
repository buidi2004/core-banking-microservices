import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ekyc_sdk/src/ui/ekyc_camera_view.dart';
import 'package:ekyc_sdk/src/liveness/active_liveness_detector.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  group('BiometricOvalCutoutPainter Tests', () {
    test('BiometricOvalCutoutPainter paints even-odd path without throwing', () {
      const painter = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(50, 100, 200, 300),
        overlayColor: Color(0xB3000000),
        borderColor: Color(0xFF00E5FF),
        borderWidth: 2.5,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 600);

      // Verify painting runs smoothly with zero errors
      expect(() => painter.paint(canvas, size), returnsNormally);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('BiometricOvalCutoutPainter shouldRepaint responds correctly to property changes', () {
      const painterA = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(50, 100, 200, 300),
      );
      const painterB = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(50, 100, 200, 300),
      );
      const painterC = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(60, 100, 200, 300),
      );

      expect(painterA.shouldRepaint(painterB), isFalse);
      expect(painterA.shouldRepaint(painterC), isTrue);
    });
  });

  group('ActiveLivenessDetector Face Inside Oval Geometry Tests', () {
    test('Face centered within tolerance is recognized inside oval', () {
      final detector = ActiveLivenessDetector();

      // Giả lập khuôn mặt nằm chính giữa màn hình (width: 480, height: 640)
      // Trung tâm: (240, 320)
      final face = Face(
        boundingBox: const Rect.fromLTWH(140, 200, 200, 240), // Center: (240, 320), width: 200 (41.6% of 480)
        landmarks: {},
        contours: {},
      );

      final isInside = detector.isFaceInsideOval(
        face: face,
        previewWidth: 480,
        previewHeight: 640,
      );

      expect(isInside, isTrue);
    });

    test('Face shifted beyond 22% tolerance is rejected', () {
      final detector = ActiveLivenessDetector();

      // Khuôn mặt bị lệch sang góc trái quá mức
      final face = Face(
        boundingBox: const Rect.fromLTWH(10, 200, 200, 240), // Center: (110, 320) -> diffX = 130 > 480 * 0.22 = 105.6
        landmarks: {},
        contours: {},
      );

      final isInside = detector.isFaceInsideOval(
        face: face,
        previewWidth: 480,
        previewHeight: 640,
      );

      expect(isInside, isFalse);
    });
  });
}
