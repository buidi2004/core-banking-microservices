/// Nguồn: audit AUDIT-MOB-BE-001, commit 75bf273.
///
/// Đây là **nguồn sự thật duy nhất** về khả năng của backend mà mobile được
/// phép sử dụng. Mọi màn hình/datasource phải tra cứu ở đây trước khi gọi
/// API, tránh gọi endpoint không tồn tại (404) hoặc báo "thành công" giả.
///
/// ## Điều khiển bằng `--dart-define` (vòng 2 — R2-P1-02)
///
/// Mọi cờ đọc từ biến môi trường compile-time, **mặc định `false`** (an toàn,
/// khớp baseline backend `75bf273`):
///
/// ```bash
/// flutter run --dart-define=BE_CAP_TRANSACTION_PIN=true
/// flutter test --dart-define=BE_CAP_TRANSACTION_PIN=true
/// ```
///
/// Chỉ nhận giá trị `true` / `TRUE`; mọi giá trị khác ⇒ `false` (fail-safe).
///
/// ⚠️ **KHÔNG được tự ý bật cờ.** Bật cờ đồng nghĩa với việc tuyên bố rằng
/// backend đã có API tương ứng. Việc đó đòi hỏi:
///   1) backend đã được kiểm thử (mvn test) và E2E (`RUN_E2E=true flutter test --tags e2e`);
///   2) chủ repo đã phê duyệt thay đổi backend (xem
///      `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md` — R2-P0-01);
///   3) hợp đồng request/response đã khớp 100%.
///
/// Xem thêm: `01_ISSUES_AND_TASKS.md` §14.2 (R2-P1-02) và §15.1 (W2).
class BackendCapabilities {
  BackendCapabilities._();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Capability flags — mặc định đều `false` (backend baseline 75bf273)
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

  /// BE đã cung cấp receipt/export endpoints (TransactionHistoryController).
  static const bool receiptAndExport = bool.fromEnvironment('BE_CAP_RECEIPT_EXPORT', defaultValue: false);

  /// BE đã cung cấp referral endpoints (ReferralController).
  static const bool referrals = bool.fromEnvironment('BE_CAP_REFERRALS', defaultValue: false);

  /// BE đã cung cấp legal documents endpoints (LegalController).
  static const bool legalDocuments = bool.fromEnvironment('BE_CAP_LEGAL', defaultValue: false);

  /// BE đã cung cấp feedback endpoints (FeedbackController).
  static const bool feedback = bool.fromEnvironment('BE_CAP_FEEDBACK', defaultValue: false);

  /// BE chưa có producer tạo thông báo Khuyến mãi / Hệ thống (chỉ có BALANCE) — BE-REQ-PROMO.
  static const bool promoAndSystemNotifications =
      bool.fromEnvironment('BE_CAP_PROMO_SYSTEM', defaultValue: false);

  /// BE đã cung cấp money-request detail/cancel endpoints (MoneyRequestController).
  static const bool moneyRequestDetail = bool.fromEnvironment('BE_CAP_MONEY_REQUEST_DETAIL', defaultValue: false);

  /// BE đã cung cấp money-request cancel endpoints (MoneyRequestController).
  static const bool moneyRequestCancel = bool.fromEnvironment('BE_CAP_MONEY_REQUEST_CANCEL', defaultValue: false);

  /// BE đã cung cấp API sổ tiết kiệm core banking (SavingsController qua payment-service).
  static const bool savings = bool.fromEnvironment('BE_CAP_SAVINGS', defaultValue: true);

  /// BE đã cung cấp API vay tiêu dùng core banking (LoanController qua payment-service).
  static const bool loans = bool.fromEnvironment('BE_CAP_LOANS', defaultValue: true);

  // ---------------------------------------------------------------------------
  // Tra cứu endpoint theo đường dẫn (W3 — một nơi quyết định duy nhất)
  // ---------------------------------------------------------------------------

  /// Các hằng đường dẫn mà backend chưa có.
  static const Set<String> knownBackendGaps = <String>{
    '/config/limits',
    '/config/limits/status',
  };

  /// Các route có **tham số động** mà backend chưa có.
  static final List<RegExp> knownBackendGapPatterns = <RegExp>[
    RegExp(r'^/transactions/export/.*'),
    RegExp(r'^/transactions/.+/receipt\.pdf$'),
  ];

  /// `true` nếu [path] **không** nằm trong danh mục endpoint chưa có ở backend.
  ///
  /// Dùng để chặn trước khi phát HTTP:
  /// ```dart
  /// if (!BackendCapabilities.hasEndpoint(ApiConstants.billPay)) {
  ///   return showFeatureUnavailable(context, feature: 'Thanh toán hóa đơn');
  /// }
  /// ```
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
