class ApiConstants {
  ApiConstants._();

  // Base URLs - Mặc định kết nối trực tiếp API Gateway Local (:8080), có thể override qua --dart-define
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api/v1');
  static const String wsUrl = String.fromEnvironment('API_WS_URL', defaultValue: 'ws://localhost:8080/ws-native');
  static const String wsTopicPrefix = '/topic/wallets';
  static String walletNotificationTopic(String walletId) => '/topic/wallets/$walletId/notifications';
  static String userNotificationTopic(String userId) => '/topic/users/$userId/notifications';

  // Localhost alternatives:
  // Android Emulator: http://10.0.2.2:8080/api/v1
  // iOS Simulator: http://localhost:8080/api/v1

  // Auth endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String register = '/auth/register';
  static const String otpVerify = '/auth/otp/verify';
  static const String otpSend = '/auth/otp/send';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String setPin = '/users/pin/set';
  static const String verifyPin = '/users/pin/verify';
  static const String biometricVerify = '/security/biometric/verify';

  // Wallet & Transfer endpoints

  // Wallet & Transfer endpoints
  static const String walletMe = '/wallets/me';
  static String walletDetail(String walletId) => '/wallets/$walletId';
  static const String recipientInfo = '/wallets/recipient-info';
  static const String estimateFee = '/wallets/fees/estimate';
  static const String paymentTransfer = '/payments/transfer';
  static const String transferInit = '/wallets/transfer/init';
  static String transferConfirm(String id) => '/wallets/transfer/$id/confirm';
  static const String deposit = '/wallets/deposit';
  static const String withdraw = '/wallets/withdraw';

  // Profile endpoint
  static const String userProfile = '/users/profile';

  // Transactions & Statement
  static const String transactions = '/transactions';
  static String transactionDetail(String id) => '/transactions/$id';
  static String receiptPdf(String id) => '/transactions/$id/receipt.pdf';
  static String exportTransactions(String format) => '/transactions/export/$format';

  // QR Code
  static const String decodeVietQr = '/payments/vietqr/decode';
  static const String generateVietQr = '/payments/vietqr/generate';
  static const String myQrCode = '/users/me/qrcode';

  // Bills & Utilities
  static const String billLookup = '/bills/lookup';
  static const String billPay = '/bills/pay';
  static const String billTopup = '/bills/topup';

  // Sources & Banks
  static const String banks = '/banks';
  static const String beneficiaries = '/beneficiaries';
  static const String fundingSources = '/funding-sources';
  static const String bankAccounts = '/bank-accounts';

  // User Profile & KYC
  static const String userMe = '/users/me';
  static const String userAvatar = '/users/me/avatar';
  static const String kycSubmit = '/kyc/submit';
  static const String kycStatus = '/kyc/status';
  static const String limitStatus = '/config/limits/status';

  // Sessions & Notifications
  static const String sessions = '/sessions';
  static String sessionDetail(String sessionId) => '/sessions/$sessionId';
  static String sessionFcm(String deviceId) => '/sessions/$deviceId/fcm';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String notificationsSettings = '/notifications/settings';
  static String readNotification(String id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';
  static const String faq = '/support/faq';
  static const String tickets = '/support/tickets';

  // Bank Accounts Link & Unlink
  static const String bankAccountsLink = '/bank-accounts/link';
  static String bankAccountDetail(String id) => '/bank-accounts/$id';

  // Config & Legal
  static const String configLimits = '/config/limits';
  static const String legalTerms = '/legal/terms';
  static const String legalConsent = '/legal/consent';

  // Money Requests
  static const String moneyRequests = '/payments/money-requests';
  static String moneyRequestsUser(String userId) => '/payments/money-requests/user/$userId';
  static const String moneyRequestsReceived = '/payments/money-requests/received';
  static const String moneyRequestsSent = '/payments/money-requests/sent';
  static String moneyRequestDetail(String id) => '/payments/money-requests/$id';
  static String moneyRequestAccept(String id) => '/payments/money-requests/$id/accept';
  static String moneyRequestReject(String id) => '/payments/money-requests/$id/reject';
  static String moneyRequestCancel(String id) => '/payments/money-requests/$id/cancel';

  // Promotions & Referrals & Feedback
  static const String promotions = '/promotions';
  static const String myVouchers = '/promotions/my-vouchers';
  static const String redeemPromotion = '/promotions/redeem';
  static const String applyPromotion = '/promotions/apply';
  static const String referralCode = '/referrals/code';
  static const String referralHistory = '/referrals/history';
  static const String applyReferral = '/referrals/apply';
  static const String feedback = '/feedback';

  // Devices & FCM Push
  static const String deviceRegister = '/devices/register';
  static const String deviceUnregister = '/devices/unregister';
}
