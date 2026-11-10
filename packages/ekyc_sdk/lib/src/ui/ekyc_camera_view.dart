import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../liveness/active_liveness_detector.dart';

final Map<DeviceOrientation, int> _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Painter vẽ khung phủ đen mờ và đục lỗ bầu dục vector bằng PathFillType.evenOdd.
/// Hoạt động 100% trong suốt mượt mà trên cả Skia và Impeller (Android Vulkan / iOS Metal).
class BiometricOvalCutoutPainter extends CustomPainter {
  final Rect ovalRect;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;

  const BiometricOvalCutoutPainter({
    required this.ovalRect,
    this.overlayColor = const Color(0xB3000000), // 70% black
    this.borderColor = const Color(0xFF00E5FF),
    this.borderWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(bgRect)
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = overlayColor);

    // Viền dạ quang neon bao quanh lỗ đục
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant BiometricOvalCutoutPainter oldDelegate) {
    return oldDelegate.ovalRect != ovalRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

class EkycCameraView extends StatefulWidget {
  final Function(XFile bestFrame) onCompleted;
  final VoidCallback? onCancel;

  const EkycCameraView({
    super.key,
    required this.onCompleted,
    this.onCancel,
  });

  @override
  State<EkycCameraView> createState() => _EkycCameraViewState();
}

class _EkycCameraViewState extends State<EkycCameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  late final ActiveLivenessDetector _livenessDetector;

  bool _isProcessingFrame = false;
  bool _isFinished = false;
  bool _hasCameraError = false;
  int _lastProcessedMs = 0;
  String _hintMessage = 'Căn chỉnh khuôn mặt vào giữa khung bầu dục';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _livenessDetector = ActiveLivenessDetector();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _hasCameraError = true);
        return;
      }
      // Ưu tiên camera trước (front camera) cho eKYC selfie
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Khởi tạo camera với cấu hình tương thích 100% Android CameraX & iOS
      // Tuyệt đối không ép ImageFormatGroup.nv21 trên CameraController vì sẽ làm đen
      // màn hình SurfaceTexture của CameraPreview trên Samsung One UI (Galaxy A/S/Note).
      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _hasCameraError = false;
      });

      // Chờ Flutter mount SurfaceTexture của CameraPreview vào native view trước khi
      // bắt đầu nhận luồng ảnh, tránh xung đột tài nguyên SurfaceRequest trên CameraX
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || _cameraController != controller) return;

      await controller.startImageStream((image) => _processCameraImage(image));
    } catch (e) {
      debugPrint('[eKYC] Camera init fatal error: $e');
      if (!mounted) return;
      setState(() => _hasCameraError = true);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _isFinished) return;
    // Throttle ~10fps: camera stream 30fps nhưng platform channel chỉ nhận
    // khung đủ xử lý — khung thừa bị bỏ qua TRƯỚC khi vào kênh ML Kit.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastProcessedMs < 100) return;
    _lastProcessedMs = nowMs;
    _isProcessingFrame = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        if (mounted) {
          setState(() => _hintMessage = 'Không tìm thấy khuôn mặt, vui lòng nhìn thẳng vào camera');
        }
        return;
      }

      // Lọc khuôn mặt CHÍNH: ưu tiên diện tích lớn nhất gần tâm ảnh nhất,
      // chống bắt nhầm người đi ngang hậu cảnh
      Face face = faces.first;
      if (faces.length > 1) {
        final imgCenter = Offset(image.width / 2.0, image.height * 0.42);
        double bestRank = -1;
        for (final f in faces) {
          final area = f.boundingBox.width * f.boundingBox.height;
          final dist = (f.boundingBox.center - imgCenter).distance;
          final maxDim = image.width > image.height ? image.width : image.height;
          final normDist = (dist / (maxDim / 2.0)).clamp(0.0, 1.0);
          final rank = area * (1.0 - 0.5 * normDist);
          if (rank > bestRank) {
            bestRank = rank;
            face = f;
          }
        }
      }

      // Khi ảnh xoay 90 hoặc 270 độ, kích thước chiều rộng/cao trong ML Kit bị hoán đổi
      final imageRotation = _cameraController?.description.sensorOrientation ?? 0;
      final isRotated = imageRotation == 90 || imageRotation == 270;
      final previewWidth = isRotated ? image.height.toDouble() : image.width.toDouble();
      final previewHeight = isRotated ? image.width.toDouble() : image.height.toDouble();

      final inOval = _livenessDetector.isFaceInsideOval(
        face: face,
        previewWidth: previewWidth,
        previewHeight: previewHeight,
      );

      if (!inOval) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng đưa mặt vào giữa khung bầu dục');
        }
        return;
      }

      // Kiểm tra góc nghiêng mặt (Pitch: ngẩng/cúi cằm, Roll: nghiêng sang vai)
      // Dung sai nới lỏng ±16° cho tư thế cầm điện thoại tự nhiên theo QĐ 2345
      final pitch = face.headEulerAngleX ?? 0.0;
      final roll = face.headEulerAngleZ ?? 0.0;
      if (pitch.abs() > 16.0) {
        if (mounted) {
          setState(() => _hintMessage = pitch > 0
              ? 'Vui lòng hạ cằm xuống, nhìn thẳng vào camera'
              : 'Vui lòng nâng cằm lên, nhìn thẳng vào camera');
        }
        return;
      }
      if (roll.abs() > 16.0) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng giữ thẳng đầu, không nghiêng sang vai');
        }
        return;
      }

      // Kiểm tra phụ kiện che điểm mốc (kính râm, khẩu trang, tóc che mắt)
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      if (leftEye == null || rightEye == null || nose == null) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng không đeo kính râm, tháo khẩu trang và vén tóc che mắt');
        }
        return;
      }

      // Kiểm tra khoảng cách: tỷ lệ vàng 30% - 75% chiều rộng ảnh (khoảng cách 35 - 45 cm)
      final faceRatio = face.boundingBox.width / previewWidth;
      if (faceRatio < 0.30) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng đưa điện thoại lại gần hơn');
        }
        return;
      } else if (faceRatio > 0.75) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng đưa điện thoại ra xa một chút');
        }
        return;
      }

      // Xử lý bước thử thách sinh trắc
      final passedStep = _livenessDetector.processFace(face);
      if (passedStep) {
        HapticFeedback.mediumImpact();
        if (_livenessDetector.isCompleted) {
          _isFinished = true;
          HapticFeedback.heavyImpact();
          if (mounted) {
            setState(() => _hintMessage = 'Giữ yên khuôn mặt để chụp ảnh chân dung...');
          }
          await _cameraController?.stopImageStream();
          // Chờ 350ms để cơ mặt trở về trạng thái tĩnh tự nhiên sau khi cười/nháy mắt
          await Future.delayed(const Duration(milliseconds: 350));
          final bestFrame = await _cameraController?.takePicture();
          if (bestFrame != null && mounted) {
            widget.onCompleted(bestFrame);
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _hintMessage = _livenessDetector.currentChallenge?.instruction ?? 'Đang hoàn tất...';
        });
      }
    } catch (err) {
      debugPrint('[eKYC] Error processing camera frame: $err');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final camera = controller.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[controller.value.deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    rotation ??= InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    // Chuẩn bị byte buffer hỗ trợ đa hình (1 plane, 2 planes, hoặc 3 planes)
    Uint8List bytes;
    InputImageFormat format;

    if (image.planes.length == 1) {
      final plane = image.planes[0];
      if (plane.bytesPerRow == image.width) {
        bytes = plane.bytes;
      } else {
        final buffer = Uint8List(image.width * image.height);
        for (var y = 0; y < image.height; y++) {
          final srcOffset = y * plane.bytesPerRow;
          final dstOffset = y * image.width;
          buffer.setRange(dstOffset, dstOffset + image.width, plane.bytes, srcOffset);
        }
        bytes = buffer;
      }
      format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    } else if (image.planes.length == 2) {
      // NV21 (Android 2 planes: Plane 0 = Y, Plane 1 = VU interleaved)
      // KHÔNG TRUY CẬP planes[2] để tránh RangeError (Index out of range)
      final yPlane = image.planes[0];
      final vuPlane = image.planes[1];

      final ySize = image.width * image.height;
      final vuSize = image.width * (image.height ~/ 2);
      final nv21 = Uint8List(ySize + vuSize);

      var dstIndex = 0;
      for (var y = 0; y < image.height; y++) {
        final srcOffset = y * yPlane.bytesPerRow;
        nv21.setRange(dstIndex, dstIndex + image.width, yPlane.bytes, srcOffset);
        dstIndex += image.width;
      }

      final vuHeight = image.height ~/ 2;
      for (var y = 0; y < vuHeight; y++) {
        final srcOffset = y * vuPlane.bytesPerRow;
        final copyLen = image.width;
        if (srcOffset + copyLen <= vuPlane.bytes.length && dstIndex + copyLen <= nv21.length) {
          nv21.setRange(dstIndex, dstIndex + copyLen, vuPlane.bytes, srcOffset);
          dstIndex += copyLen;
        } else {
          final rem = (vuPlane.bytes.length - srcOffset).clamp(0, copyLen);
          if (rem > 0 && dstIndex + rem <= nv21.length) {
            nv21.setRange(dstIndex, dstIndex + rem, vuPlane.bytes, srcOffset);
            dstIndex += rem;
          }
        }
      }
      bytes = nv21;
      format = InputImageFormat.nv21;
    } else {
      // YUV420_888 (Android 3 planes: Plane 0 = Y, Plane 1 = U, Plane 2 = V)
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final ySize = image.width * image.height;
      final uvSize = image.width * (image.height ~/ 2);
      final nv21 = Uint8List(ySize + uvSize);

      var dstIndex = 0;
      for (var y = 0; y < image.height; y++) {
        final srcOffset = y * yPlane.bytesPerRow;
        nv21.setRange(dstIndex, dstIndex + image.width, yPlane.bytes, srcOffset);
        dstIndex += image.width;
      }

      final uvWidth = image.width ~/ 2;
      final uvHeight = image.height ~/ 2;
      final int uPixelStride = uPlane.bytesPerPixel ?? 1;
      final int vPixelStride = vPlane.bytesPerPixel ?? 1;

      for (var y = 0; y < uvHeight; y++) {
        final uRowOffset = y * uPlane.bytesPerRow;
        final vRowOffset = y * vPlane.bytesPerRow;
        for (var x = 0; x < uvWidth; x++) {
          final vIndex = vRowOffset + x * vPixelStride;
          final uIndex = uRowOffset + x * uPixelStride;
          if (vIndex < vPlane.bytes.length && dstIndex < nv21.length) {
            nv21[dstIndex++] = vPlane.bytes[vIndex];
          }
          if (uIndex < uPlane.bytes.length && dstIndex < nv21.length) {
            nv21[dstIndex++] = uPlane.bytes[uIndex];
          }
        }
      }
      bytes = nv21;
      format = InputImageFormat.nv21;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCameraError) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle,
                color: Colors.white54, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Không truy cập được camera.\nVui lòng cấp quyền camera và thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                setState(() => _hasCameraError = false);
                _initializeCamera();
              },
              icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CupertinoActivityIndicator(color: Colors.white, radius: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Tính toán kích thước khung bầu dục vừa vặn với kích thước thẻ cha
        final ovalWidth = width * 0.70;
        final ovalHeight = height * 0.65;
        final ovalCenter = Offset(width / 2.0, height * 0.44);
        final ovalRect = Rect.fromCenter(
          center: ovalCenter,
          width: ovalWidth,
          height: ovalHeight,
        );

        final previewSize = controller.value.previewSize;
        double previewW = width;
        double previewH = height;
        if (previewSize != null) {
          // Chuẩn hóa kích thước cảm biến cho màn hình dọc (portrait):
          // Chiều rộng hiển thị luôn là cạnh nhỏ hơn, chiều cao là cạnh lớn hơn.
          // Tránh hoán đổi vô điều kiện khiến preview biến thành khung ngang (landscape) bị đen màn.
          final double smaller = previewSize.width < previewSize.height ? previewSize.width : previewSize.height;
          final double larger = previewSize.width < previewSize.height ? previewSize.height : previewSize.width;
          previewW = smaller;
          previewH = larger;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Preview lấp đầy khung hình (FittedBox cover không biến dạng)
            ClipRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewW,
                    height: previewH,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),

            // 2. Vector Cutout Overlay với CustomPainter (Trong suốt 100% trên Impeller & Skia)
            CustomPaint(
              size: Size(width, height),
              painter: BiometricOvalCutoutPainter(
                ovalRect: ovalRect,
                overlayColor: Colors.black.withOpacity(0.60),
                borderColor: const Color(0xFF00E5FF),
                borderWidth: 2.5,
              ),
            ),

              // 3. Tiến trình & Nút hủy ở đỉnh khung (chỉ hiện nút X nếu có onCancel)
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.onCancel != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(CupertinoIcons.xmark_circle_fill,
                                color: Colors.white70, size: 24),
                            onPressed: widget.onCancel,
                          )
                        else
                          const SizedBox(width: 24),
                        Text(
                          'Bước ${_livenessDetector.currentStepNumber}/${_livenessDetector.totalSteps}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _livenessDetector.progress,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        minHeight: 3.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Khung thông điệp chỉ dẫn ở đáy
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 0.5),
                  ),
                  child: Text(
                    _hintMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
}
