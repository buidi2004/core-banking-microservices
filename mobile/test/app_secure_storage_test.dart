import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

class _MissingPluginStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future<String?>.error(MissingPluginException());

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future<void>.error(MissingPluginException());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSecureStorage configuration & extractErrorMessage tests', () {
    test('AppSecureStorage provides singleton instance with resetOnError enabled', () {
      expect(AppSecureStorage.instance, isNotNull);
      expect(AppSecureStorage.androidOptions, isNotNull);
    });

    test('safeRead does not hide a missing secure-storage plugin', () async {
      await expectLater(
        AppSecureStorage.safeRead(_MissingPluginStorage(), key: 'token'),
        throwsA(isA<MissingPluginException>()),
      );
    });

    test('safeWrite does not reset storage when the plugin is unavailable', () async {
      await expectLater(
        AppSecureStorage.safeWrite(
          _MissingPluginStorage(),
          key: 'token',
          value: 'secret',
        ),
        throwsA(isA<MissingPluginException>()),
      );
    });

    test('extractErrorMessage handles BadPaddingException gracefully', () {
      const rawError =
          'PlatformException(Exception encountered, read, javax.crypto.BadPaddingException: 1e000065:Cipher functions:OPENSSL_internal:BAD_DECRYPT)';
      final result = extractErrorMessage(rawError);
      expect(result, contains('Khóa bảo mật'));
      expect(result, contains('Đăng nhập lại'));
    });

    test('extractErrorMessage handles BAD_DECRYPT error gracefully', () {
      const rawError = 'javax.crypto.AEADBadTagException: BAD_DECRYPT';
      final result = extractErrorMessage(rawError);
      expect(result, contains('Khóa bảo mật'));
    });

    test('extractErrorMessage handles PlatformException biometric NotAvailable', () {
      const rawError = 'PlatformException(NotAvailable, Biometrics not available, null, null)';
      final result = extractErrorMessage(rawError);
      expect(result, contains('chưa cài đặt'));
    });

    test('extractErrorMessage handles PlatformException LockedOut', () {
      const rawError = 'PlatformException(LockedOut, Too many attempts, null, null)';
      final result = extractErrorMessage(rawError);
      expect(result, contains('mã PIN'));
    });
  });
}
