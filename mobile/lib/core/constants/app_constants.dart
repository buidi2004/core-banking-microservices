class AppConstants {
  AppConstants._();

  static const String appName = 'Sen Hồng Bank';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyPhoneNumber = 'phone_number';
  static const String keyFullName = 'full_name';
  static const String keyWalletId = 'wallet_id';
  static const String keyAvatarUrl = 'avatar_url';
  static const String keyPinToken = 'pin_token';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyHideBalance = 'hide_balance';
  static const String keyGlassQuality = 'glass_quality_settled';

  // Limits
  static const int pinLength = 6;
  static const int otpLength = 6;
  static const int otpCountdownSeconds = 60;
}
