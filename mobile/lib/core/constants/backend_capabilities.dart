/// Nguồn: Hệ thống kết nối Microservices Core Banking & Mobile Sen Hồng.
///
/// Đây là bộ cờ năng lực kiểm soát tính khả dụng của Backend đối với Mobile.
/// Mọi cờ đọc từ biến môi trường compile-time, có thể bật qua `--dart-define`.
class BackendCapabilities {
  BackendCapabilities._();

  // ---------------------------------------------------------------------------
  // Capability flags — Mặc định phản ánh baseline tích hợp
  // ---------------------------------------------------------------------------

  /// Đã tích hợp xác thực PIN giao dịch server-side qua /users/pin/verify và validate pinToken trong saga (BE-REQ-03)
  static const bool serverSideTransferAuth = bool.fromEnvironment('BE_CAP_TRANSFER_AUTH', defaultValue: true);

  /// Đã tích hợp API OTP/PIN cho onboarding và quên mật khẩu qua identity-service (BE-REQ-04)
  static const bool otp = bool.fromEnvironment('BE_CAP_OTP', defaultValue: true);

  /// Đã tích hợp API quản lý và xác thực mã PIN qua identity-service (BE-REQ-03)
  static const bool transactionPin = bool.fromEnvironment('BE_CAP_TRANSACTION_PIN', defaultValue: true);

  /// BE đã cung cấp deposit/withdraw user-level (WalletMutationController & DepositWithdrawController)
  static const bool deposit = bool.fromEnvironment('BE_CAP_DEPOSIT', defaultValue: true);

  /// BE đã cung cấp withdraw user-level (WalletMutationController & DepositWithdrawController)
  static const bool withdraw = bool.fromEnvironment('BE_CAP_WITHDRAW', defaultValue: true);

  /// BE đã cung cấp bills/* endpoints (BillController)
  static const bool bills = bool.fromEnvironment('BE_CAP_BILLS', defaultValue: true);

  /// BE đã cung cấp VietQR endpoints (VietQrController)
  static const bool vietQr = bool.fromEnvironment('BE_CAP_VIETQR', defaultValue: true);

  /// BE đã cung cấp bank-accounts endpoints (BankAccountController)
  static const bool bankAccounts = bool.fromEnvironment('BE_CAP_BANK_ACCOUNTS', defaultValue: true);

  /// BE đã cung cấp funding-sources endpoints (FundingSourceController)
  static const bool fundingSources = bool.fromEnvironment('BE_CAP_FUNDING_SOURCES', defaultValue: true);

  /// BE đã cung cấp beneficiaries endpoints (BeneficiaryController)
  static const bool beneficiaries = bool.fromEnvironment('BE_CAP_BENEFICIARIES', defaultValue: true);

  /// BE cung cấp receipt/export endpoints (TransactionHistoryController & ReceiptExportService)
  static const bool receiptAndExport = bool.fromEnvironment('BE_CAP_RECEIPT_EXPORT', defaultValue: false);

  /// BE cung cấp referral endpoints (ReferralController)
  static const bool referrals = bool.fromEnvironment('BE_CAP_REFERRALS', defaultValue: false);

  /// BE cung cấp legal documents endpoints (LegalController)
  static const bool legalDocuments = bool.fromEnvironment('BE_CAP_LEGAL', defaultValue: false);

  /// BE cung cấp feedback endpoints (FeedbackController)
  static const bool feedback = bool.fromEnvironment('BE_CAP_FEEDBACK', defaultValue: false);

  /// BE tạo thông báo Khuyến mãi / Hệ thống (PromotionController)
  static const bool promoAndSystemNotifications =
      bool.fromEnvironment('BE_CAP_PROMO_SYSTEM', defaultValue: false);

  /// BE cung cấp money-request detail endpoints (MoneyRequestController)
  static const bool moneyRequestDetail = bool.fromEnvironment('BE_CAP_MONEY_REQUEST_DETAIL', defaultValue: false);

  /// BE cung cấp money-request cancel endpoints (MoneyRequestController)
  static const bool moneyRequestCancel = bool.fromEnvironment('BE_CAP_MONEY_REQUEST_CANCEL', defaultValue: false);

  /// BE đã cung cấp API sổ tiết kiệm core banking (SavingsController qua payment-service).
  static const bool savings = bool.fromEnvironment('BE_CAP_SAVINGS', defaultValue: true);

  /// BE đã cung cấp API vay tiêu dùng core banking (LoanController qua payment-service).
  static const bool loans = bool.fromEnvironment('BE_CAP_LOANS', defaultValue: true);

  // ---------------------------------------------------------------------------
  // Tra cứu endpoint theo đường dẫn
  // ---------------------------------------------------------------------------

  /// Các hằng đường dẫn bị chặn ở client-side guard
  static const Set<String> knownBackendGaps = <String>{
    // BE-REQ-06 — biên lai / xuất sao kê
    '/transactions/export',
    // BE-REQ-06 — cấu hình hạn mức
    '/config/limits',
    '/config/limits/status',
  };

  /// Các route có tham số động bị chặn ở client-side guard
  static final List<RegExp> knownBackendGapPatterns = <RegExp>[
    // GET /transactions/{id}/receipt.pdf
    RegExp(r'/transactions/[^/]+/receipt\.pdf$'),
  ];

  /// `true` nếu [path] được backend hỗ trợ
  static bool hasEndpoint(String path) {
    for (final gap in knownBackendGaps) {
      if (path == gap || path.startsWith('$gap/')) return false;
    }
    for (final pattern in knownBackendGapPatterns) {
      if (pattern.hasMatch(path)) return false;
    }
    return true;
  }
}
