import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../liveness/active_liveness_detector.dart';

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

class _EkycCameraViewState extends State<EkycCameraView> {
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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Ưu tiên camera trước (front camera) cho eKYC selfie
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // ResolutionPreset.medium cho LUỒNG detection: giảm ~60% byte truyền qua
      // platform channel (tránh nghẽn 30fps full-res gây đơ UI). Ảnh chính
      // vẫn chụp full resolution riêng bằng takePicture() ở bước cuối.
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {});

      _cameraController!.startImageStream((image) => _processCameraImage(image));
    } catch (e) {
      // Không có camera/quyền/phần cứng (test, emulator rỗng) — báo lỗi trung thực
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
      final previewWidth = image.width.toDouble();
      final previewHeight = image.height.toDouble();

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

      // Kiểm tra góc nghiêng mặt (Pitch: trục ngẩng/cúi cằm, Roll: trục nghiêng sang vai)
      // Khóa chặt trong khoảng [-10, +10] độ theo chuẩn QĐ 2345/QĐ-NHNN chống méo góc cằm/mũi
      final pitch = face.headEulerAngleX ?? 0.0;
      final roll = face.headEulerAngleZ ?? 0.0;
      if (pitch.abs() > 10.0) {
        if (mounted) {
          setState(() => _hintMessage = pitch > 0
              ? 'Vui lòng hạ cằm xuống, nhìn thẳng vào camera'
              : 'Vui lòng nâng cằm lên, nhìn thẳng vào camera');
        }
        return;
      }
      if (roll.abs() > 10.0) {
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

      // Kiểm tra khoảng cách: tỷ lệ vàng 32% - 68% chiều rộng ảnh (khoảng cách 35 - 45 cm)
      final faceRatio = face.boundingBox.width / previewWidth;
      if (faceRatio < 0.32) {
        if (mounted) {
          setState(() => _hintMessage = 'Vui lòng đưa điện thoại lại gần hơn');
        }
        return;
      } else if (faceRatio > 0.68) {
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
    } catch (_) {
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    final imageRotation = _cameraController?.description.sensorOrientation ?? 0;
    final rotation = InputImageRotationValue.fromRawValue(imageRotation) ?? InputImageRotation.rotation0deg;

    // Xử lý lệch byte đệm dòng (row padding / stride) trên máy Samsung & Android CameraX
    Uint8List bytes;
    if (image.planes.length == 1) {
      final plane = image.planes[0];
      if (plane.bytesPerRow == image.width) {
        bytes = plane.bytes;
      } else {
        // Loại bỏ padding thừa ở cuối mỗi hàng pixel
        final buffer = Uint8List(image.width * image.height);
        for (var y = 0; y < image.height; y++) {
          final srcOffset = y * plane.bytesPerRow;
          final dstOffset = y * image.width;
          buffer.setRange(dstOffset, dstOffset + image.width, plane.bytes, srcOffset);
        }
        bytes = buffer;
      }
    } else {
      // YUV420_888 sang NV21 chuẩn: khử row padding cho plane Y và interleave V/U
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
          if (vIndex < vPlane.bytes.length) {
            nv21[dstIndex++] = vPlane.bytes[vIndex];
          }
          if (uIndex < uPlane.bytes.length) {
            nv21[dstIndex++] = uPlane.bytes[uIndex];
          }
        }
      }
      bytes = nv21;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCameraError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle,
                    color: Colors.white54, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Không truy cập được camera.\nVui lòng cấp quyền camera và thử lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _hasCameraError = false);
                    _initializeCamera();
                  },
                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          CameraPreview(_cameraController!),

          // 2. Lớp phủ khung bầu dục (Biometric Oval Mask)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.15),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.72,
                    height: MediaQuery.of(context).size.width * 0.98,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(
                          MediaQuery.of(context).size.width * 0.72,
                          MediaQuery.of(context).size.width * 0.98,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Viền dạ quang cho khung bầu dục
          Align(
            alignment: const Alignment(0, -0.15),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: MediaQuery.of(context).size.width * 0.98,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(
                    MediaQuery.of(context).size.width * 0.72,
                    MediaQuery.of(context).size.width * 0.98,
                  ),
                ),
              ),
            ),
          ),

          // 4. Thanh tiến trình & Hướng dẫn trên đầu
          Positioned(
            top: 54,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 28),
                      onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Bước ${_livenessDetector.currentStepNumber}/${_livenessDetector.totalSteps}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _livenessDetector.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          // 5. Khung thông điệp chỉ dẫn ở đáy
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 0.5),
              ),
              child: Text(
                _hintMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

