import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSecureStorage configuration & extractErrorMessage tests', () {
    test('AppSecureStorage provides singleton instance with resetOnError enabled', () {
      expect(AppSecureStorage.instance, isNotNull);
      expect(AppSecureStorage.androidOptions, isNotNull);
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
