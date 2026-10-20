/// Nguồn: audit AUDIT-MOB-BE-001, commit 75bf273.
/// Bật lại khi backend bổ sung endpoint tương ứng (xem BE-REQ trong 01_ISSUES_AND_TASKS.md).
class BackendCapabilities {
  BackendCapabilities._();

  /// BE chưa cung cấp API xác thực PIN/OTP cho giao dịch chuyển tiền ⇒ chặn giao dịch tại mobile
  static const bool serverSideTransferAuth = false; // BE-REQ-03

  /// BE chưa cung cấp API OTP/PIN cho onboarding ⇒ bỏ bước bắt buộc, đưa ngay Home
  static const bool otp = false;                    // BE-REQ-04

  /// BE chưa cung cấp API PIN/OTP xác thực ⇒ giao dịch tạm khóa
  static const bool transactionPin = false;         // BE-REQ-03

  /// BE chưa cung cấp deposit/withdraw user-level
  static const bool deposit = false;                // BE-REQ-06

  /// BE chưa cung cấp withdraw user-level
  static const bool withdraw = false;               // BE-REQ-06

  /// BE chưa cung cấp bills/* endpoints
  static const bool bills = false;                  // BE-REQ-06

  /// BE chưa cung cấp VietQR endpoints
  static const bool vietQr = false;                 // BE-REQ-06

  /// BE chưa cung cấp bank-accounts endpoints
  static const bool bankAccounts = false;           // BE-REQ-06

  /// BE chưa cung cấp funding-sources endpoints
  static const bool fundingSources = false;         // BE-REQ-06

  /// BE chưa cung beneficiaries endpoints
  static const bool beneficiaries = false;          // BE-REQ-06

  /// BE chưa cung receipt/export endpoints
  static const bool receiptAndExport = false;       // BE-REQ-06

  /// BE chưa cungReferral endpoints
  static const bool referrals = false;              // BE-REQ-06

  /// BE chưa cung legal Documents endpoints
  static const bool legalDocuments = false;         // BE-REQ-06

  /// BE chưa cung feedback endpoints
  static const bool feedback = false;               // BE-REQ-06

  /// BE chưa cung money-request detail/cancel endpoints
  static const bool moneyRequestDetail = false;     // BE-REQ-06
  static const bool moneyRequestCancel = false;     // BE-REQ-06
}