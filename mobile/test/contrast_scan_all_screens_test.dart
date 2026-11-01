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
import 'package:sen_hong_bank/presentation/screens/transfer/beneficiaries_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/choose_recipient_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/confirm_transfer_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/enter_amount_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/request_transfer_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/transfer_result_screen.dart';

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
    'TransferRecipient': const ChooseRecipientScreen(),
    'TransferAmount': const EnterAmountScreen(
      recipient: 'Nguyễn Văn A',
      phoneNumber: '0901234567',
      initialAmount: 500000,
      initialNote: 'Chuyen tien',
    ),
    'TransferConfirm': const ConfirmTransferScreen(
      recipient: 'Nguyễn Văn A',
      phoneNumber: '0901234567',
      amount: 500000,
      note: 'Chuyen tien',
    ),
    'TransferResult': const TransferResultScreen(
      recipient: 'Nguyễn Văn A',
      phoneNumber: '0901234567',
      amount: 500000,
      note: 'Chuyen tien',
      transactionId: 'TX-1',
    ),
    'TransferRequest': const RequestTransferScreen(),
    'Beneficiaries': const BeneficiariesScreen(),
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
    // Mô phỏng chiều rộng iPhone phổ biến để bắt lỗi bố cục tràn trên mobile.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var totalText = 0;
    var totalTextIssues = 0;
    var totalIcon = 0;
    var totalIconIssues = 0;
    final summary = <String>[];

    // Ghi nhận lỗi render trong lúc cuộn để audit không âm thầm bỏ qua
    // RenderFlex overflow và exception phát sinh dưới nếp gấp.
    final originalOnError = FlutterError.onError;
    final renderErrors = <String>[];
    FlutterError.onError = (FlutterErrorDetails details) {
      if (renderErrors.length >= 5) return;
      final flexContext = details.informationCollector
              ?.call()
              .map((node) => node.toString())
              .join(' ') ??
          '';
      renderErrors.add(
        '${details.exceptionAsString().split('\n').first} '
        '${details.context?.toString() ?? ''} $flexContext',
      );
    };

    for (final entry in screens.entries) {
      try {
        renderErrors.clear();
        await tester.pumpWidget(auditHarness(entry.value));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final textFindingMap = <String, TextContrastFinding>{};
        final iconFindingMap = <String, IconContrastFinding>{};
        // Quét nhiều viewport để thấy nội dung ở dưới nếp gấp, không chỉ phần
        // đầu màn hình. Khóa theo nội dung/màu/nền để tránh đếm lặp khi cuộn.
        for (var viewport = 0; viewport < 8; viewport++) {
          for (final finding in collectTextFindings(tester)) {
            final key =
                '${finding.text}|${finding.color}|${finding.background}';
            textFindingMap[key] = finding;
          }
          for (final finding in collectIconFindings(tester)) {
            final key =
                '${finding.icon}|${finding.color}|${finding.background}';
            iconFindingMap[key] = finding;
          }
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isEmpty) break;
          final scrollable = scrollables.first;
          final state = tester.state<ScrollableState>(scrollable);
          if (state.position.extentAfter <= 1) break;
          await tester.drag(
            scrollable,
            Offset(0, -state.position.viewportDimension * 0.75),
          );
          await tester.pump(const Duration(milliseconds: 250));
        }
        final textFindings = textFindingMap.values.toList();
        final iconFindings = iconFindingMap.values.toList();

        final textIssues = textFindings.where((f) => !f.passesAa).length;
        final iconIssues = iconFindings.where((f) => !f.passes).length;
        totalText += textFindings.length;
        totalTextIssues += textIssues;
        totalIcon += iconFindings.length;
        totalIconIssues += iconIssues;
        summary.add('${entry.key}: chữ ${textFindings.length}/lỗi $textIssues'
            ' · icon ${iconFindings.length}/lỗi $iconIssues');
        if (renderErrors.isNotEmpty) {
          summary.add('  ${entry.key}: LỖI BỐ CỤC — '
              '${renderErrors.toSet().join(' | ')}');
        }
        printContrastReport(entry.key, textFindings);
        printIconReport(entry.key, iconFindings);
      } catch (e) {
        summary.add(
            '${entry.key}: LỖI RENDER — ${e.toString().split('\n').first}');
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
