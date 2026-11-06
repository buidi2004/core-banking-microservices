import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Bộ đệm L1 RAM cache tốc độ cao (0ms, loại bỏ overhead MethodChannel IPC cho mỗi request)
  static final Map<String, String> _memoryCache = {};

  /// Đọc dữ liệu an toàn từ L1 Cache hoặc SecureStorage.
  static Future<String?> safeRead(FlutterSecureStorage storage, {required String key}) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    try {
      final val = await storage.read(key: key);
      if (val != null) {
        _memoryCache[key] = val;
      }
      return val;
    } on MissingPluginException {
      rethrow;
    } catch (e) {
      debugPrint('[AppSecureStorage] Lỗi an toàn khi đọc khóa $key: $e');
      return null;
    }
  }

  /// Ghi dữ liệu an toàn vào SecureStorage và cập nhật L1 cache.
  static Future<void> safeWrite(FlutterSecureStorage storage, {required String key, required String value}) async {
    _memoryCache[key] = value;
    try {
      await storage.write(key: key, value: value);
    } on MissingPluginException {
      rethrow;
    } catch (e) {
      debugPrint('[AppSecureStorage] Lỗi an toàn khi ghi khóa $key: $e. Đang thiết lập lại...');
      try {
        await storage.deleteAll();
        await storage.write(key: key, value: value);
      } on MissingPluginException {
        rethrow;
      } catch (e) {
        if (e is MissingPluginException) {
          rethrow;
        }
      }
    }
  }

  /// Xóa khóa an toàn khỏi cả L1 cache và SecureStorage.
  static Future<void> safeDelete(FlutterSecureStorage storage, {required String key}) async {
    _memoryCache.remove(key);
    try {
      await storage.delete(key: key);
    } on MissingPluginException {
      rethrow;
    } catch (_) {}
  }

  /// Xóa toàn bộ dữ liệu an toàn
  static Future<void> safeDeleteAll(FlutterSecureStorage storage) async {
    _memoryCache.clear();
    try {
      await storage.deleteAll();
    } catch (_) {}
  }
}
