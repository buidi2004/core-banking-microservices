class ApiConstants {
  ApiConstants._();

  // Base URLs - Cố định kết nối qua Ngrok Public Tunnel
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mutation-tubby-overstock.ngrok-free.dev/api/v1',
  );
  static const String wsUrl = String.fromEnvironment(
    'API_WS_URL',
    defaultValue: 'wss://mutation-tubby-overstock.ngrok-free.dev/ws-native',
  );
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
  // BE-GAP (BE-REQ-04): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String otpVerify = '/auth/otp/verify';
  // BE-GAP (BE-REQ-04): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String otpSend = '/auth/otp/send';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String changePasswordOtp = '/auth/change-password/otp';
  static const String changePinOtp = '/auth/change-pin/otp';
  static const String loanOtp = '/auth/loan/otp';
  static const String loanOtpVerify = '/auth/loan/otp/verify';
  static const String logout = '/auth/logout';
  // BE-GAP (BE-REQ-03): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String setPin = '/users/pin/set';
  // BE-GAP (BE-REQ-03): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String verifyPin = '/users/pin/verify';
  static const String biometricVerify = '/security/biometric/verify';
  static const String emergencyLock = '/security/emergency-lock';

  // Wallet & Transfer endpoints

  // Wallet & Transfer endpoints
  static const String walletMe = '/wallets/me';
  static String walletDetail(String walletId) => '/wallets/$walletId';
  static const String recipientInfo = '/wallets/recipient-info';
  static const String estimateFee = '/wallets/fees/estimate';
  static const String paymentTransfer = '/payments/transfer';
  static const String transferInit = '/wallets/transfer/init';
  static String transferConfirm(String id) => '/wallets/transfer/$id/confirm';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String deposit = '/wallets/deposit';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String withdraw = '/wallets/withdraw';

  // Profile endpoint
  static const String userProfile = '/users/profile';

  // Transactions & Statement
  static const String transactions = '/transactions';
  static String transactionDetail(String id) => '/transactions/$id';
  static String receiptPdf(String id) => '/transactions/$id/receipt.pdf';
  static String exportTransactions(String format) => '/transactions/export/$format';
  static const String disputes = '/payments/disputes';
  static String disputeDetail(String id) => '/payments/disputes/$id';

  // QR Code
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String decodeVietQr = '/payments/vietqr/decode';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String generateVietQr = '/payments/vietqr/generate';
  static const String myQrCode = '/users/me/qrcode';

  // Bills & Utilities
  static const String billLookup = '/bills/lookup';
  static const String billPay = '/bills/pay';
  static const String billTopup = '/bills/topup';
  static const String billSubscriptions = '/bills/subscriptions';
  static String billSubscriptionDetail(String id) => '/bills/subscriptions/$id';

  // Sources & Banks
  static const String banks = '/banks';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String beneficiaries = '/beneficiaries';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String fundingSources = '/funding-sources';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String bankAccounts = '/bank-accounts';

  // User Profile & KYC
  static const String userMe = '/users/me';
  static const String userAlias = '/users/me/alias';
  static const String userAvatar = '/users/me/avatar';
  static const String kycSubmit = '/kyc/submit';
  static const String kycStatus = '/kyc/status';
  static const String ekycAiSession = '/ekyc/ai/session';
  static const String ekycAiVerify = '/ekyc/ai/verify';
  static const String ekycAiHealth = '/ekyc/ai/health';

  static const String ekycServerPublicKeyPem = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzyHR+zayzca2BUUyx+O
ByAq9NGEqidBjZGX0NNf4cRW9im+SRffnkLB+Iku8zZnvoCIMCCEjVYawIJS2XRK
bqbQCAKCbE1Q/lITdEaDaPDvaCd5Mr8aIsKY9LewTFKy57JdAvSdvoSOidNMn4R6
y86oA9F+YHHj2L1KtskhpV4uZFwhUfjsA/wQOgZgMXzcGu/xD7jh9m9K0PswRwPq
l9PIozREDnN8sCLnUllE3E/jf05TI++94E+DrAd0GRljhIzufWI+3F97z9OWAPh6
YLvBXJ00qIERcfgVcqtrpKBK2K7bYM5PEoyJMMjccxSya2ZEtt+2KYPSr6s3AtG/
wQIDAQAB
-----END PUBLIC KEY-----''';
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
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
  static String bankAccountDefault(String id) => '/bank-accounts/$id/default';

  // Config & Legal
  // BE-GAP (BE-REQ-06): backend baseline (75bf273) chưa có endpoint này — mọi call site phải gate bằng BackendCapabilities.showFeatureUnavailable
  static const String configLimits = '/config/limits';
  static const String legalTerms = '/legal/terms';
  static const String legalConsent = '/legal/consent';

  // Cards CMS
  static const String cards = '/cards';
  static const String cardIssue = '/cards/issue';
  static String cardStatus(String id) => '/cards/$id/status';
  static String cardSettings(String id) => '/cards/$id/settings';

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
  static const String promotionCampaigns = '/promotions/campaigns';
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

  // Savings Online (Core Banking In-house)
  static const String savingsProducts = '/savings/products';
  static const String savingsAccounts = '/savings/accounts';
  static String savingsDetail(String id) => '/savings/accounts/$id';
  static String savingsSettle(String id) => '/savings/accounts/$id/settle';
  static String savingsWithdrawPartial(String id) => '/savings/accounts/$id/withdraw-partial';

  // Scheduled & Recurring Transfers
  static const String scheduledTransfers = '/payments/scheduled-transfers';
  static String scheduledTransferDetail(String id) => '/payments/scheduled-transfers/$id';

  // Quick Loans (Core Banking In-house)
  static const String loanProducts = '/loans/products';
  static const String loanApply = '/loans/apply';
  static const String loans = '/loans';
  static String loanDetail(String id) => '/loans/$id';
  static String loanSchedule(String id) => '/loans/$id/schedule';
  static String loanRepay(String id) => '/loans/$id/repay';
  static String loanSettleEarly(String id) => '/loans/$id/settle';

  // AI Chatbot RAG Assistant 24/7
  static const String chat = '/chat';

  // Lottery Vietlott Core Banking
  static const String lotteryBuy = '/lottery/buy';
  static const String lotteryMyTickets = '/lottery/my-tickets';
  static const String lotteryResults = '/lottery/results';
}
