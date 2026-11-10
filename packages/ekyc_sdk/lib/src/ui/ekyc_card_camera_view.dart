import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Camera chụp ảnh thẻ CCCD (mặt trước/sau) — khung chữ nhật căn chỉnh,
/// nút chụp thủ công, trả về bytes ảnh JPEG qua callback.
/// Hỗ trợ chạm để lấy nét (tap-to-focus) và bật/tắt đèn pin (torch).
class EkycCardCameraView extends StatefulWidget {
  final String title;
  final String hint;
  final ValueChanged<Uint8List> onCaptured;
  final VoidCallback? onCancel;

  const EkycCardCameraView({
    super.key,
    required this.title,
    required this.hint,
    required this.onCaptured,
    this.onCancel,
  });

  @override
  State<EkycCardCameraView> createState() => _EkycCardCameraViewState();
}

class _EkycCardCameraViewState extends State<EkycCardCameraView> {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isTorchOn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Thiết bị không có camera khả dụng';
        });
        return;
      }
      // Ưu tiên camera sau cho chụp giấy tờ
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Không thể khởi động camera: $e';
      });
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _cameraController!.setFlashMode(
        _isTorchOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_isCapturing || _cameraController == null) return;
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();
    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) widget.onCaptured(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark,
                        color: Colors.white, size: 26),
                    onPressed:
                        widget.onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
                      color: _isTorchOn ? Colors.amberAccent : Colors.white70,
                      size: 22,
                    ),
                    onPressed: _toggleTorch,
                    tooltip: 'Bật/tắt đèn flash',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildCameraArea()),
            // Hint + nút chụp
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Text(
                    widget.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isCapturing ||
                              _isInitializing ||
                              _errorMessage != null)
                          ? null
                          : _capture,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(CupertinoIcons.camera_fill, size: 20),
                      label: Text(_isCapturing ? 'Đang chụp...' : 'Chụp ảnh'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_isInitializing) {
      return const Center(
          child: CupertinoActivityIndicator(color: Colors.white, radius: 16));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white54, size: 44),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) async {
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final size = renderBox.size;
                    final point = Offset(
                      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
                      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
                    );
                    try {
                      await _cameraController!.setFocusPoint(point);
                      await _cameraController!.setExposurePoint(point);
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                  }
                }
              },
              child: CameraPreview(_cameraController!),
            ),
            // Khung căn chỉnh thẻ (tỷ lệ ID-2 ≈ 85.6×54mm)
            IgnorePointer(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.width * 0.82 * 54.0 / 85.6,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
