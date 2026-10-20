import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bộ quản lý lưu trữ bảo mật cấp ứng dụng (chuẩn ngân hàng).
/// Được cấu hình tự động xử lý và phục hồi khi KeyStore của thiết bị Android bị lỗi hoặc đổi khóa
/// (như BadPaddingException, Cipher BAD_DECRYPT sau khi backup, update hoặc cài đè bản build).
class AppSecureStorage {
  static const AndroidOptions androidOptions = AndroidOptions(
    resetOnError: true,
  );

  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  );

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: iosOptions,
  );

  /// Đọc dữ liệu an toàn từ SecureStorage. Không xóa khóa ngoài ý muốn khi hệ thống Keychain bận.
  static Future<String?> safeRead(FlutterSecureStorage storage, {required String key}) async {
    try {
      return await storage.read(key: key);
    } catch (e) {
      debugPrint('[AppSecureStorage] Lỗi an toàn khi đọc khóa $key: $e');
      return null;
    }
  }

  /// Ghi dữ liệu an toàn vào SecureStorage. Nếu phát hiện lỗi native cipher, tự động dọn dẹp và ghi lại.
  static Future<void> safeWrite(FlutterSecureStorage storage, {required String key, required String value}) async {
    try {
      await storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[AppSecureStorage] Lỗi an toàn khi ghi khóa $key: $e. Đang thiết lập lại...');
      try {
        await storage.deleteAll();
        await storage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  /// Xóa khóa an toàn, không ném exception nếu native KeyStore gặp trục trặc.
  static Future<void> safeDelete(FlutterSecureStorage storage, {required String key}) async {
    try {
      await storage.delete(key: key);
    } catch (_) {}
  }

  /// Xóa toàn bộ dữ liệu an toàn
  static Future<void> safeDeleteAll(FlutterSecureStorage storage) async {
    try {
      await storage.deleteAll();
    } catch (_) {}
  }
}
