import 'dart:typed_data';
import 'dart:ui' as ui;

/// Bộ tiện ích xử lý ảnh chuyên dụng cho eKYC:
/// - Khử lỗi xoay ngang EXIF qua Hardware Accelerated Codec của Skia/Impeller
/// - Giới hạn kích thước ảnh (targetWidth: 720 - 1080px)
/// - Tránh đơ màn hình UI (tránh drop frame)
class EkycImageUtils {
  /// Chuẩn hóa mảng byte ảnh chụp trước khi gửi lên AI Microservice
  static Future<Uint8List> prepareImageBytes(
    Uint8List rawBytes, {
    int targetWidth = 1080,
  }) async {
    if (rawBytes.isEmpty) return rawBytes;

    final codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: targetWidth,
      allowUpscaling: false,
    );
    final frameInfo = await codec.getNextFrame();
    final byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    frameInfo.image.dispose();
    codec.dispose();

    if (byteData == null) return rawBytes;
    return byteData.buffer.asUint8List();
  }
}
