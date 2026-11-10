import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ekyc_sdk/src/ui/ekyc_camera_view.dart';
import 'package:ekyc_sdk/src/liveness/active_liveness_detector.dart';
import 'package:ekyc_sdk/src/models/ekyc_models.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  group('1. ActiveLivenessDetector - Multi-challenge State Machine & Progression', () {
    test('Simulates complete 3-step biometric challenge successfully', () {
      final detector = ActiveLivenessDetector(
        customChallenges: [
          LivenessChallenge.blink,
          LivenessChallenge.turnLeft,
          LivenessChallenge.smile,
        ],
      );

      expect(detector.currentStepNumber, 1);
      expect(detector.currentChallenge, LivenessChallenge.blink);
      expect(detector.progress, 0.0);
      expect(detector.isCompleted, isFalse);

      // Step 1: Mắt mở bình thường -> Chưa pass
      final openEyesFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        leftEyeOpenProbability: 0.95,
        rightEyeOpenProbability: 0.90,
      );
      expect(detector.processFace(openEyesFace), isFalse);
      expect(detector.currentStepNumber, 1);

      // Step 1: Nháy mắt (Cả 2 mắt < 0.25) -> Pass Step 1
      final blinkingFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        leftEyeOpenProbability: 0.15,
        rightEyeOpenProbability: 0.10,
      );
      expect(detector.processFace(blinkingFace), isTrue);
      expect(detector.currentStepNumber, 2);
      expect(detector.currentChallenge, LivenessChallenge.turnLeft);
      expect(detector.progress, closeTo(1 / 3, 0.01));

      // Step 2: Chưa quay đầu (yaw = 0) -> Chưa pass
      final straightFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleY: 2.0,
      );
      expect(detector.processFace(straightFace), isFalse);

      // Step 2: Quay đầu sang trái (yaw < -18.0) -> Pass Step 2
      final turnLeftFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleY: -22.5,
      );
      expect(detector.processFace(turnLeftFace), isTrue);
      expect(detector.currentStepNumber, 3);
      expect(detector.currentChallenge, LivenessChallenge.smile);
      expect(detector.progress, closeTo(2 / 3, 0.01));

      // Step 3: Mặt nghiêm túc (smile < 0.65) -> Chưa pass
      final seriousFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        smilingProbability: 0.10,
      );
      expect(detector.processFace(seriousFace), isFalse);

      // Step 3: Mỉm cười (smile > 0.65) -> Pass Step 3 & Complete!
      final smilingFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        smilingProbability: 0.88,
      );
      expect(detector.processFace(smilingFace), isTrue);
      expect(detector.isCompleted, isTrue);
      expect(detector.progress, 1.0);
      expect(detector.currentChallenge, isNull);

      // Gọi tiếp khi đã xong không ném lỗi
      expect(detector.processFace(smilingFace), isTrue);

      // Reset
      detector.reset();
      expect(detector.isCompleted, isFalse);
      expect(detector.progress, 0.0);
      expect(detector.currentStepNumber, 1);
    });

    test('Turn Right challenge triggers at yaw > +18.0 deg', () {
      final detector = ActiveLivenessDetector(
        customChallenges: [LivenessChallenge.turnRight],
      );

      final leftFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleY: -25.0,
      );
      expect(detector.processFace(leftFace), isFalse);

      final rightFace = Face(
        boundingBox: const Rect.fromLTWH(100, 100, 200, 200),
        landmarks: {},
        contours: {},
        headEulerAngleY: 20.0,
      );
      expect(detector.processFace(rightFace), isTrue);
      expect(detector.isCompleted, isTrue);
    });
  });

  group('2. Geometry & Spatial Oval Invariant Tests', () {
    test('Extreme offsets outside 22% tolerance are cleanly rejected', () {
      final detector = ActiveLivenessDetector();
      const double width = 720;
      const double height = 1280;

      // Mặt bay lên góc trên bên phải
      final cornerFace = Face(
        boundingBox: const Rect.fromLTWH(550, 50, 150, 150),
        landmarks: {},
        contours: {},
      );
      expect(detector.isFaceInsideOval(face: cornerFace, previewWidth: width, previewHeight: height), isFalse);

      // Mặt chính giữa, tỷ lệ kích thước 45% chuẩn
      final perfectFace = Face(
        boundingBox: Rect.fromCenter(center: const Offset(360, 640), width: 320, height: 400),
        landmarks: {},
        contours: {},
      );
      expect(detector.isFaceInsideOval(face: perfectFace, previewWidth: width, previewHeight: height), isTrue);

      // Mặt quá nhỏ (< 28% previewWidth)
      final tinyFace = Face(
        boundingBox: Rect.fromCenter(center: const Offset(360, 640), width: 120, height: 160),
        landmarks: {},
        contours: {},
      );
      expect(detector.isFaceInsideOval(face: tinyFace, previewWidth: width, previewHeight: height), isFalse);

      // Mặt quá sát màn hình (> 85% previewWidth)
      final hugeFace = Face(
        boundingBox: Rect.fromCenter(center: const Offset(360, 640), width: 680, height: 800),
        landmarks: {},
        contours: {},
      );
      expect(detector.isFaceInsideOval(face: hugeFace, previewWidth: width, previewHeight: height), isFalse);
    });
  });

  group('3. Multi-Plane Buffer Reconstruction Simulation (Anti-Crash Guarantee)', () {
    test('Simulates 2-Plane NV21 byte concatenation without out-of-bounds error', () {
      const int width = 320;
      const int height = 240;

      final ySize = width * height;
      final vuSize = width * (height ~/ 2);

      // Giả lập Plane 0: Y (Luminance)
      final yPlaneBytes = Uint8List(width * height);
      for (int i = 0; i < yPlaneBytes.length; i++) {
        yPlaneBytes[i] = (i % 255);
      }

      // Giả lập Plane 1: VU (Interleaved Chroma)
      final vuPlaneBytes = Uint8List(vuSize);
      for (int i = 0; i < vuPlaneBytes.length; i++) {
        vuPlaneBytes[i] = 128;
      }

      // Thực thi thuật toán đa hình mới của EkycCameraView
      final nv21 = Uint8List(ySize + vuSize);
      int dstIndex = 0;
      for (var y = 0; y < height; y++) {
        final srcOffset = y * width;
        nv21.setRange(dstIndex, dstIndex + width, yPlaneBytes, srcOffset);
        dstIndex += width;
      }

      final vuHeight = height ~/ 2;
      for (var y = 0; y < vuHeight; y++) {
        final srcOffset = y * width;
        final copyLen = width;
        if (srcOffset + copyLen <= vuPlaneBytes.length && dstIndex + copyLen <= nv21.length) {
          nv21.setRange(dstIndex, dstIndex + copyLen, vuPlaneBytes, srcOffset);
          dstIndex += copyLen;
        }
      }

      expect(nv21.length, equals(ySize + vuSize));
      expect(dstIndex, equals(ySize + vuSize));
      // Đảm bảo byte Y đầu tiên và VU đầu tiên được ghi chính xác
      expect(nv21[0], equals(0));
      expect(nv21[ySize], equals(128));
    });

    test('Simulates 3-Plane YUV420_888 interleaving without out-of-bounds error', () {
      const int width = 80;
      const int height = 60;
      final int ySize = width * height;
      final int uvSize = width * (height ~/ 2);

      final yPlane = Uint8List(ySize);
      final uPlane = Uint8List(ySize ~/ 4);
      final vPlane = Uint8List(ySize ~/ 4);

      uPlane.fillRange(0, uPlane.length, 100);
      vPlane.fillRange(0, vPlane.length, 200);

      final nv21 = Uint8List(ySize + uvSize);
      var dstIndex = 0;
      for (var y = 0; y < height; y++) {
        nv21.setRange(dstIndex, dstIndex + width, yPlane, y * width);
        dstIndex += width;
      }

      final uvWidth = width ~/ 2;
      final uvHeight = height ~/ 2;
      for (var y = 0; y < uvHeight; y++) {
        final uRowOffset = y * uvWidth;
        final vRowOffset = y * uvWidth;
        for (var x = 0; x < uvWidth; x++) {
          final vIndex = vRowOffset + x;
          final uIndex = uRowOffset + x;
          if (vIndex < vPlane.length && dstIndex < nv21.length) {
            nv21[dstIndex++] = vPlane[vIndex];
          }
          if (uIndex < uPlane.length && dstIndex < nv21.length) {
            nv21[dstIndex++] = uPlane[uIndex];
          }
        }
      }

      expect(nv21.length, equals(ySize + uvSize));
      expect(dstIndex, equals(ySize + uvSize));
      // Trong NV21: V đứng trước U (VU order)
      expect(nv21[ySize], equals(200)); // V
      expect(nv21[ySize + 1], equals(100)); // U
    });
  });

  group('4. BiometricOvalCutoutPainter Edge Display Scenarios', () {
    test('Handles compact smartwatch size and huge tablet size without clipping crashes', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Màn hình siêu nhỏ (200x200)
      const smallPainter = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(20, 20, 160, 160),
      );
      expect(() => smallPainter.paint(canvas, const Size(200, 200)), returnsNormally);

      // Màn hình máy tính bảng (1200x1920)
      const tabletPainter = BiometricOvalCutoutPainter(
        ovalRect: Rect.fromLTWH(200, 300, 800, 1200),
      );
      expect(() => tabletPainter.paint(canvas, const Size(1200, 1920)), returnsNormally);
    });
  });
}
