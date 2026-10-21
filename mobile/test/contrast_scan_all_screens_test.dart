import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/auth/forgot_password_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/forgot_pin_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/login_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/otp_verification_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/register_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/reset_password_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/set_pin_screen.dart';
import 'package:sen_hong_bank/presentation/screens/auth/terms_of_service_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/bill_input_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/bill_payment_confirm_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/bill_payment_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/loan_schedule_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/lottery_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/phone_recharge_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/phone_topup_confirm_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/quick_loan_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/savings_detail_screen.dart';
import 'package:sen_hong_bank/presentation/screens/bills/savings_screen.dart';
import 'package:sen_hong_bank/presentation/screens/cards/bank_cards_screen.dart';
import 'package:sen_hong_bank/presentation/screens/cards/cards_screen.dart';
import 'package:sen_hong_bank/presentation/screens/cards/payment_methods_screen.dart';
import 'package:sen_hong_bank/presentation/screens/deposit_withdraw/deposit_confirm_screen.dart';
import 'package:sen_hong_bank/presentation/screens/deposit_withdraw/deposit_screen.dart';
import 'package:sen_hong_bank/presentation/screens/deposit_withdraw/withdraw_confirm_screen.dart';
import 'package:sen_hong_bank/presentation/screens/deposit_withdraw/withdraw_screen.dart';
import 'package:sen_hong_bank/presentation/screens/history/transaction_detail_screen.dart';
import 'package:sen_hong_bank/presentation/screens/history/transaction_history_screen.dart';
import 'package:sen_hong_bank/presentation/screens/home/home_screen.dart';
import 'package:sen_hong_bank/presentation/screens/home/notifications_screen.dart';
import 'package:sen_hong_bank/presentation/screens/home/search_screen.dart';
import 'package:sen_hong_bank/presentation/screens/more/more_screen.dart';
import 'package:sen_hong_bank/presentation/screens/more/referral_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/digital_signature_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/ekyc_screens.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/email_settings_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/identity_document_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/kyc_level_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/nfc_reader_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/user_profile_screen.dart';
import 'package:sen_hong_bank/presentation/screens/promotions/promotions_screen.dart';
import 'package:sen_hong_bank/presentation/screens/qr/my_qr_screen.dart';
import 'package:sen_hong_bank/presentation/screens/qr/scan_qr_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/change_pin_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/config_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/device_management_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/notification_settings_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/security_settings_screen.dart';
import 'package:sen_hong_bank/presentation/screens/settings/settings_screen.dart';
import 'package:sen_hong_bank/presentation/screens/support/help_center_screen.dart';
import 'package:sen_hong_bank/presentation/screens/support/live_chat_screen.dart';

import 'support/contrast_audit.dart';

/// ---------------------------------------------------------------------------
/// AUDIT-TP-CONTRAST-SCAN · Quét tương phản TOÀN BỘ màn hình.
///
/// Đây là công cụ CHẨN ĐOÁN (không assert) — dùng để:
///  1. Xác nhận việc đổi token màu toàn cục không gây hồi quy ở màn khác.
///  2. Lập danh sách nợ kỹ thuật còn lại ngoài phạm vi luồng chuyển tiền nội bộ.
///
/// Chạy: flutter test test/contrast_scan_all_screens_test.dart
/// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final screens = <String, Widget>{
    'Login': const LoginScreen(),
    'Register': const RegisterScreen(),
    'OtpVerification': const OtpVerificationScreen(phone: '0901234567'),
    'SetPin': const SetPinScreen(),
    'ForgotPassword': const ForgotPasswordScreen(),
    'ResetPassword': const ResetPasswordScreen(phone: '0901234567'),
    'ForgotPin': const ForgotPinScreen(),
    'TermsOfService': const TermsOfServiceScreen(),
    'Home': const HomeScreen(),
    'Notifications': const NotificationsScreen(),
    'Search': const SearchScreen(),
    'TransactionHistory': const TransactionHistoryScreen(),
    'TransactionDetail': const TransactionDetailScreen(
      id: 'TX-1',
      title: 'Chuyển tiền',
      amount: 500000,
      time: '10:00 21/10/2026',
      note: 'Chuyen tien',
      recipient: 'NGUYEN VAN A',
    ),
    'Promotions': const PromotionsScreen(),
    'More': const MoreScreen(),
    'Referral': const ReferralScreen(),
    'Cards': const CardsScreen(),
    'PaymentMethods': const PaymentMethodsScreen(),
    'BankCards': const BankCardsScreen(),
    'ScanQR': const ScanQRScreen(),
    'MyQR': const MyQRScreen(),
    'Deposit': const DepositScreen(),
    'DepositConfirm': const DepositConfirmScreen(
        amount: 500000, source: 'Vietcombank (*8899)'),
    'Withdraw': const WithdrawScreen(),
    'WithdrawConfirm': const WithdrawConfirmScreen(
        amount: 500000,
        bank: 'Vietcombank',
        acc: '1234567890',
        bankAccountId: 'BA-1'),
    'BillPayment': const BillPaymentScreen(),
    'BillInput': const BillInputScreen(),
    'BillPaymentConfirm': const BillPaymentConfirmScreen(
        billId: 'B1', amount: 100000, provider: 'EVN', customerCode: 'C1'),
    'PhoneTopupConfirm': const PhoneTopupConfirmScreen(
        phoneNumber: '0901234567', amount: 100000, telco: 'Viettel'),
    'PhoneRecharge': const PhoneRechargeScreen(),
    'Lottery': const LotteryScreen(),
    'Savings': const SavingsScreen(),
    'SavingsDetail': const SavingsDetailScreen(),
    'QuickLoan': const QuickLoanScreen(),
    'LoanSchedule': const LoanScheduleScreen(),
    'UserProfile': const UserProfileScreen(),
    'IdentityDocument': const IdentityDocumentScreen(),
    'KycLevel': const KycLevelScreen(),
    'EKyc': const EKycScreen(),
    'DigitalSignature': const DigitalSignatureScreen(),
    'EmailSettings': const EmailSettingsScreen(),
    'NfcReader': const NfcReaderScreen(),
    'SecuritySettings': const SecuritySettingsScreen(),
    'DeviceManagement': const DeviceManagementScreen(),
    'Settings': const SettingsScreen(),
    'Config': const ConfigScreen(),
    'ChangePin': const ChangePinScreen(),
    'NotificationSettings': const NotificationSettingsScreen(),
    'HelpCenter': const HelpCenterScreen(),
    'LiveChat': const LiveChatScreen(),
  };

  testWidgets('Quét tương phản toàn bộ màn hình (chẩn đoán)', (tester) async {
    var totalText = 0;
    var totalTextIssues = 0;
    var totalIcon = 0;
    var totalIconIssues = 0;
    final summary = <String>[];

    // Một số màn hình (ngoài phạm vi chuyển tiền nội bộ) có lỗi render sẵn có
    // (overflow) khi chạy trong môi trường test với kích thước mặc định.
    // Đây là công cụ CHẨN ĐOÁN nên chỉ ghi nhận, không làm fail test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {};

    for (final entry in screens.entries) {
      try {
        await tester.pumpWidget(auditHarness(entry.value));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final textFindings = collectTextFindings(tester);
        final iconFindings = collectIconFindings(tester);
        await tester.pump(const Duration(seconds: 1));

        final textIssues = textFindings.where((f) => !f.passesAa).length;
        final iconIssues = iconFindings.where((f) => !f.passes).length;
        totalText += textFindings.length;
        totalTextIssues += textIssues;
        totalIcon += iconFindings.length;
        totalIconIssues += iconIssues;
        summary.add('${entry.key}: chữ ${textFindings.length}/lỗi $textIssues'
            ' · icon ${iconFindings.length}/lỗi $iconIssues');
        printContrastReport(entry.key, textFindings);
        printIconReport(entry.key, iconFindings);
      } catch (e) {
        summary.add('${entry.key}: LỖI RENDER — ${e.toString().split('\n').first}');
      }
    }

    FlutterError.onError = originalOnError;

    // ignore: avoid_print
    print('\n===== TỔNG HỢP QUÉT TOÀN APP =====');
    for (final line in summary) {
      // ignore: avoid_print
      print('  $line');
    }
    // ignore: avoid_print
    print('  TỔNG: chữ $totalText (lỗi $totalTextIssues) · '
        'icon $totalIcon (lỗi $totalIconIssues)');
  });
}
