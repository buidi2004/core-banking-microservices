import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveIdentity({required String userId, required String phoneNumber});
  Future<void> saveFullName(String fullName);
  Future<String?> getFullName();
  Future<void> saveWalletId(String walletId);
  Future<String?> getWalletId();
  Future<void> setHideBalance(bool hide);
  Future<bool> getHideBalance();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl({
    FlutterSecureStorage? secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage ?? AppSecureStorage.instance,
        _prefs = prefs;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyAccessToken, value: accessToken);
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyRefreshToken, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return await AppSecureStorage.safeRead(_secureStorage, key: AppConstants.keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await AppSecureStorage.safeRead(_secureStorage, key: AppConstants.keyRefreshToken);
  }


  @override
  Future<void> clearTokens() async {
    await AppSecureStorage.safeDelete(_secureStorage, key: AppConstants.keyAccessToken);
    await AppSecureStorage.safeDelete(_secureStorage, key: AppConstants.keyRefreshToken);
    await AppSecureStorage.safeDelete(_secureStorage, key: AppConstants.keyPinToken);
    await AppSecureStorage.safeDelete(_secureStorage, key: AppConstants.keyWalletId);
  }

  @override
  Future<void> saveIdentity({required String userId, required String phoneNumber}) async {
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyUserId, value: userId);
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyPhoneNumber, value: phoneNumber);
  }

  @override
  Future<void> saveFullName(String fullName) async {
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyFullName, value: fullName);
  }

  @override
  Future<String?> getFullName() async {
    return await AppSecureStorage.safeRead(_secureStorage, key: AppConstants.keyFullName);
  }

  @override
  Future<void> saveWalletId(String walletId) async {
    await AppSecureStorage.safeWrite(_secureStorage, key: AppConstants.keyWalletId, value: walletId);
  }

  @override
  Future<String?> getWalletId() async {
    return await AppSecureStorage.safeRead(_secureStorage, key: AppConstants.keyWalletId);
  }

  @override
  Future<void> setHideBalance(bool hide) async {
    await _prefs.setBool(AppConstants.keyHideBalance, hide);
  }

  @override
  Future<bool> getHideBalance() async {
    return _prefs.getBool(AppConstants.keyHideBalance) ?? false;
  }
}
