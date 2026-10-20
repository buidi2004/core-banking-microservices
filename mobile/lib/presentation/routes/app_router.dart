import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'smooth_page_transitions_builder.dart';

// Shell & Main Tabs
import '../screens/shell/main_tabs_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/transaction_history_screen.dart';
import '../screens/promotions/promotions_screen.dart';
import '../screens/more/more_screen.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/set_pin_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/forgot_pin_screen.dart';
import '../screens/auth/terms_of_service_screen.dart';

// Transfer & QR
import '../screens/transfer/choose_recipient_screen.dart';
import '../screens/transfer/enter_amount_screen.dart';
import '../screens/transfer/confirm_transfer_screen.dart';
import '../screens/transfer/transfer_confirm_screen.dart';
import '../screens/transfer/transfer_result_screen.dart';
import '../screens/transfer/request_transfer_screen.dart';
import '../screens/transfer/beneficiaries_screen.dart';
import '../screens/qr/scan_qr_screen.dart';
import '../screens/qr/my_qr_screen.dart';

// Deposit & Withdraw
import '../screens/deposit_withdraw/deposit_screen.dart';
import '../screens/deposit_withdraw/deposit_confirm_screen.dart';
import '../screens/deposit_withdraw/withdraw_screen.dart';
import '../screens/deposit_withdraw/withdraw_confirm_screen.dart';

// History & Detail
import '../screens/history/transaction_detail_screen.dart';

// Bills & Utilities
import '../screens/bills/bill_payment_screen.dart';
import '../screens/bills/bill_input_screen.dart';
import '../screens/bills/bill_confirm_screen.dart';
import '../screens/bills/bill_payment_confirm_screen.dart';
import '../screens/bills/phone_topup_confirm_screen.dart';
import '../screens/bills/phone_recharge_screen.dart';
import '../screens/bills/lottery_screen.dart';
import '../screens/bills/savings_screen.dart';
import '../screens/bills/quick_loan_screen.dart';

// Cards & Payment Methods
import '../screens/cards/cards_screen.dart';
import '../screens/cards/payment_methods_screen.dart';
import '../screens/cards/bank_cards_screen.dart';

// Profile & eKYC
import '../screens/profile_ekyc/user_profile_screen.dart';
import '../screens/profile_ekyc/identity_document_screen.dart';
import '../screens/profile_ekyc/kyc_level_screen.dart';
import '../screens/profile_ekyc/ekyc_screens.dart';
import '../screens/profile_ekyc/digital_signature_screen.dart';
import '../screens/profile_ekyc/email_settings_screen.dart';
import '../screens/profile_ekyc/nfc_reader_screen.dart';

// Settings & Security
import '../screens/settings/security_settings_screen.dart';
import '../screens/settings/device_management_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/config_screen.dart';
import '../screens/settings/change_pin_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/bills/savings_detail_screen.dart';
import '../screens/bills/loan_schedule_screen.dart';

// Notifications, Search & Support
import '../screens/home/notifications_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/more/referral_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_secure_storage.dart';
import '../../core/storage/app_session.dart';
import '../screens/support/help_center_screen.dart';
import '../screens/support/live_chat_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../widgets/animated_branch_container.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) async {
    final path = state.uri.toString();

    // 1. Màn hình Splash được phép chạy để hiển thị hiệu ứng khởi động
    if (path == '/splash') return null;

    // 2. Danh sách các tuyến đường công khai (không yêu cầu đăng nhập)
    final isAuthRoute = path.startsWith('/auth');
    final isPublicSupport = path == '/support/help-center' || path == '/help-center';
    final isPublicRoute = isAuthRoute || isPublicSupport;

    // 3. Kiểm tra Access Token trong SecureStorage an toàn
    final token = await AppSecureStorage.safeRead(AppSecureStorage.instance, key: AppConstants.keyAccessToken);
    final isLoggedIn = token != null && token.isNotEmpty;

    // Chưa đăng nhập hoặc chưa mở khóa trong lần mở app này -> chuyển về Đăng nhập (FaceID / mật khẩu)
    if ((!isLoggedIn || !AppSession.unlocked) && !isPublicRoute) {
      return '/auth/login';
    }

    // Đã đăng nhập + đã mở khóa mà vào màn hình đăng nhập hoặc đăng ký -> chuyển về Trang chủ
    if (isLoggedIn &&
        AppSession.unlocked &&
        (path.startsWith('/auth/login') || path == '/auth/register')) {
      return '/';
    }

    return null;
  },
  routes: [
    // Màn hình Splash khởi động với hiệu ứng Hoa Sen Nở (Blooming Lotus)
    GoRoute(
      path: '/splash',
      name: 'splash',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Hiệu ứng hòa tan quang học khi chuyển tiếp vào Trang chủ:
          // Đóa sen nở phóng nhẹ (1.0 -> 1.05) và mờ dần vào Home (1.0 -> 0.0)
          final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ),
          );
          final scaleOut = Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: animation,
            child: FadeTransition(
              opacity: fadeOut,
              child: ScaleTransition(
                scale: scaleOut,
                child: child,
              ),
            ),
          );
        },
      ),
    ),

    // 4 Main Tabs (StatefulShellRoute with FloatingGlassBottomBar & Smooth Animated Transitions)
    StatefulShellRoute(
      builder: (context, state, navigationShell) {
        return MainTabsScreen(navigationShell: navigationShell);
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              name: 'history',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),
        // Tab 3: Promotions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/promotions',
              name: 'promotions',
              builder: (context, state) => const PromotionsScreen(),
            ),
          ],
        ),
        // Tab 4: More / Account
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              name: 'more',
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),

    // ==========================================
    // 1. AUTH & ONBOARDING
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/login',
      name: 'login',
      builder: (context, state) {
        final sessionExpired = state.uri.queryParameters['sessionExpired'] == 'true';
        final message = state.uri.queryParameters['message'];
        return LoginScreen(
          sessionExpired: sessionExpired,
          expiredMessage: message,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/otp',
      name: 'otp',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'];
        return OtpVerificationScreen(phone: phone);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/set-pin',
      name: 'set-pin',
      builder: (context, state) => const SetPinScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/reset-password',
      name: 'reset-password',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'];
        return ResetPasswordScreen(phone: phone);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/forgot-pin',
      name: 'forgot-pin',
      builder: (context, state) => const ForgotPinScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/terms',
      name: 'terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),

    // ==========================================
    // 2. TRANSFER & QR FLOW
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer',
      name: 'transfer',
      builder: (context, state) => const ChooseRecipientScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer/amount',
      name: 'transfer-amount',
      builder: (context, state) {
        final recipient = state.uri.queryParameters['recipient'] ?? 'Ví Sen Hồng';
        final phoneNumber = state.uri.queryParameters['phoneNumber'];
        final walletId = state.uri.queryParameters['walletId'];
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '');
        final note = state.uri.queryParameters['note'];
        return EnterAmountScreen(
          recipient: recipient,
          phoneNumber: phoneNumber,
          walletId: walletId,
          initialAmount: amount,
          initialNote: note,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer/confirm',
      name: 'transfer-confirm',
      builder: (context, state) {
        final recipient = state.uri.queryParameters['recipient'] ?? 'Ví Sen Hồng';
        final phoneNumber = state.uri.queryParameters['phoneNumber'];
        final walletId = state.uri.queryParameters['walletId'];
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final note = state.uri.queryParameters['note'] ?? 'Chuyen tien';
        return ConfirmTransferScreen(
          recipient: recipient,
          phoneNumber: phoneNumber,
          walletId: walletId,
          amount: amount,
          note: note,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer/2fa-otp',
      name: 'transfer-2fa-otp',
      builder: (context, state) {
        final recipient = state.uri.queryParameters['recipient'] ?? 'Ví Sen Hồng';
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final note = state.uri.queryParameters['note'] ?? 'Chuyen tien';
        return TransferConfirmScreen(
          recipient: recipient,
          amount: amount,
          note: note,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer/result',
      name: 'transfer-result',
      pageBuilder: (context, state) {
        final recipient = state.uri.queryParameters['recipient'] ?? 'Ví Sen Hồng';
        final phoneNumber = state.uri.queryParameters['phoneNumber'];
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final note = state.uri.queryParameters['note'] ?? 'Chuyen tien';
        final transactionId = state.uri.queryParameters['transactionId'];
        final status = state.uri.queryParameters['status'] ?? 'SUCCESS';
        return AppPageTransitions.celebrationZoom(
          key: state.pageKey,
          child: TransferResultScreen(
            recipient: recipient,
            phoneNumber: phoneNumber,
            amount: amount,
            note: note,
            transactionId: transactionId,
            status: status,
          ),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/transfer/request',
      name: 'transfer-request',
      builder: (context, state) => const RequestTransferScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/beneficiaries',
      name: 'beneficiaries',
      builder: (context, state) => const BeneficiariesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scan-qr',
      name: 'scan-qr',
      pageBuilder: (context, state) => AppPageTransitions.modalSlideUp(
        key: state.pageKey,
        child: const ScanQRScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/qr-scanner',
      name: 'qr-scanner',
      pageBuilder: (context, state) => AppPageTransitions.modalSlideUp(
        key: state.pageKey,
        child: const ScanQRScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/my-qr',
      name: 'my-qr',
      pageBuilder: (context, state) => AppPageTransitions.modalSlideUp(
        key: state.pageKey,
        child: const MyQRScreen(),
      ),
    ),

    // ==========================================
    // 3. DEPOSIT & WITHDRAW FLOW
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/deposit',
      name: 'deposit',
      builder: (context, state) => const DepositScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/deposit/confirm',
      name: 'deposit-confirm',
      builder: (context, state) {
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '500000') ?? 500000;
        final source = state.uri.queryParameters['source'] ?? 'Vietcombank (*8899)';
        return DepositConfirmScreen(amount: amount, source: source);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/withdraw',
      name: 'withdraw',
      builder: (context, state) => const WithdrawScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/withdraw/confirm',
      name: 'withdraw-confirm',
      builder: (context, state) {
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final bank = state.uri.queryParameters['bank'] ?? '';
        final acc = state.uri.queryParameters['acc'] ?? '';
        final bankAccountId = state.uri.queryParameters['bankAccountId'] ?? '';
        return WithdrawConfirmScreen(amount: amount, bank: bank, acc: acc, bankAccountId: bankAccountId);
      },
    ),

    // ==========================================
    // 4. HISTORY & STATEMENT
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/history/detail',
      name: 'history-detail',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        final title = state.uri.queryParameters['title'];
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '');
        final time = state.uri.queryParameters['time'];
        final note = state.uri.queryParameters['note'];
        final recipient = state.uri.queryParameters['recipient'];
        return TransactionDetailScreen(
          id: id,
          title: title,
          amount: amount,
          time: time,
          note: note,
          recipient: recipient,
        );
      },
    ),

    // ==========================================
    // 5. BILLS & FINANCIAL SERVICES
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills',
      name: 'bills',
      builder: (context, state) => const BillPaymentScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/input',
      name: 'bills-input',
      builder: (context, state) {
        final serviceType = state.uri.queryParameters['service'];
        return BillInputScreen(serviceType: serviceType);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/confirm',
      name: 'bills-confirm',
      builder: (context, state) {
        final service = state.uri.queryParameters['service'];
        final provider = state.uri.queryParameters['provider'];
        final code = state.uri.queryParameters['code'];
        final billId = state.uri.queryParameters['billId'];
        final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0');
        return BillConfirmScreen(service: service, provider: provider, code: code, billId: billId, amount: amount);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/payment-confirm',
      name: 'bills-payment-confirm',
      builder: (context, state) => BillPaymentConfirmScreen(
        billId: state.uri.queryParameters['billId'] ?? '',
        amount: double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0,
        provider: state.uri.queryParameters['provider'] ?? 'Hóa đơn',
        customerCode: state.uri.queryParameters['code'] ?? '',
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/topup-confirm',
      name: 'bills-topup-confirm',
      builder: (context, state) => PhoneTopupConfirmScreen(
        phoneNumber: state.uri.queryParameters['phone'] ?? '',
        amount: double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0,
        telco: state.uri.queryParameters['telco'] ?? 'Nhà mạng',
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/phone-recharge',
      name: 'bills-phone-recharge',
      builder: (context, state) => const PhoneRechargeScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/lottery',
      name: 'bills-lottery',
      builder: (context, state) => const LotteryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/savings',
      name: 'bills-savings',
      builder: (context, state) => const SavingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/savings',
      name: 'savings',
      builder: (context, state) => const SavingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bills/quick-loan',
      name: 'bills-quick-loan',
      builder: (context, state) => const QuickLoanScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/savings/detail',
      name: 'savings-detail',
      builder: (context, state) {
        final passbook = state.extra as Map<String, dynamic>?;
        return SavingsDetailScreen(passbook: passbook);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/loan/schedule',
      name: 'loan-schedule',
      builder: (context, state) {
        final loanData = state.extra as Map<String, dynamic>?;
        return LoanScheduleScreen(loanData: loanData);
      },
    ),

    // ==========================================
    // 6. CARDS & PAYMENT METHODS
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/cards',
      name: 'cards',
      builder: (context, state) => const CardsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/payment-methods',
      name: 'payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bank-cards',
      name: 'bank-cards',
      builder: (context, state) => const BankCardsScreen(),
    ),

    // ==========================================
    // 7. PROFILE & EKYC
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/identity',
      name: 'profile-identity',
      builder: (context, state) => const IdentityDocumentScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/identity-document',
      name: 'profile-identity-document',
      builder: (context, state) => const IdentityDocumentScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/kyc-level',
      name: 'profile-kyc-level',
      builder: (context, state) => const KycLevelScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/ekyc',
      name: 'profile-ekyc',
      builder: (context, state) => const EKycScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/digital-signature',
      name: 'profile-digital-signature',
      builder: (context, state) => const DigitalSignatureScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/email-settings',
      name: 'profile-email-settings',
      builder: (context, state) => const EmailSettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile/nfc-reader',
      name: 'profile-nfc-reader',
      builder: (context, state) => const NfcReaderScreen(),
    ),

    // ==========================================
    // 8. SETTINGS & SECURITY
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings/security',
      name: 'settings-security',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings/devices',
      name: 'settings-devices',
      builder: (context, state) => const DeviceManagementScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings/config',
      name: 'settings-config',
      builder: (context, state) => const ConfigScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings/change-pin',
      name: 'settings-change-pin',
      builder: (context, state) => const ChangePinScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications/settings',
      name: 'notifications-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),

    // ==========================================
    // 9. NOTIFICATIONS, SEARCH & SUPPORT
    // ==========================================
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) => AppPageTransitions.searchTransition(
        key: state.pageKey,
        child: const SearchScreen(),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/referral',
      name: 'referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/support/help-center',
      name: 'help-center',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/help-center',
      name: 'help-center-alias',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/support/live-chat',
      name: 'live-chat',
      builder: (context, state) => const LiveChatScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/live-chat',
      name: 'live-chat-alias',
      builder: (context, state) => const LiveChatScreen(),
    ),
  ],
);
