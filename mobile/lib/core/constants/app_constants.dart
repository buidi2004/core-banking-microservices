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
  static const String keyCitizenId = 'citizen_id';
  static const String keyDateOfBirth = 'date_of_birth';
  static const String keyGender = 'gender';
  static const String keyExpiryDate = 'expiry_date';
  static const String keyAddress = 'address';
  static const String keyIssueDate = 'issue_date';
  static const String keyKycVerified = 'kyc_verified';
  static const String keyChipPhotoBase64 = 'chip_photo_base64';

  // Limits
  static const int pinLength = 6;
  static const int otpLength = 6;
  static const int otpCountdownSeconds = 60;
}
