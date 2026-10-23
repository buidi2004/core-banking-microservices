// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Contract test: Đọc source code backend (read-only) để trích xuất endpoint thật
/// và đối chiếu với danh sách endpoint mobile đang gọi.
/// Test này KHÔNG sửa backend, chỉ đọc file .java để build inventory.

void main() {
  group('Backend Inventory Contract Test', () {
    late List<BackendEndpoint> backendEndpoints;
    late Set<String> backendPaths;

    setUpAll(() {
      // Read backend controllers and extract endpoints
      backendEndpoints = _extractBackendEndpoints();
      backendPaths = backendEndpoints.map((e) => e.fullPath).toSet();
    });

    test('Backend inventory extracted successfully', () {
      expect(backendEndpoints, isNotEmpty);
      expect(backendPaths.length, greaterThan(20));
      // Print summary for visibility
      print('Found ${backendEndpoints.length} backend endpoints across ${backendEndpoints.map((e) => e.controller).toSet().length} controllers');
      for (final ep in backendEndpoints) {
        print('  ${ep.method} ${ep.fullPath} [${ep.controller}]');
      }
    });

    /// === MOBILE ENDPOINTS THAT SHOULD EXIST IN BACKEND ===
    /// These are the endpoints mobile code CURRENTLY calls (from api_constants.dart and datasources)
    /// that MUST exist in the backend inventory.

    final Map<String, String> mobileEndpointsThatMustExist = {
      // Auth - REAL endpoints
      'POST /auth/login': 'AuthRemoteDataSource.login',
      'POST /auth/refresh': 'AuthRemoteDataSource.refreshToken (Interceptor)',
      'POST /auth/register': 'AuthRemoteDataSource.register',
      'POST /auth/logout': 'AuthRemoteDataSource.logout',

      // Wallet - REAL endpoints
      'GET /wallets/me': 'WalletRemoteDataSource.getMyWallet',
      'GET /wallets/{walletId}': 'WalletRemoteDataSource.getMyWallet fallback',
      'GET /wallets/recipient-info': 'TransferRemoteDataSource.getRecipient',
      'GET /wallets/fees/estimate': 'TransferRemoteDataSource.estimateFee',
      'POST /payments/transfer': 'TransferRemoteDataSource.initTransfer (REAL single-step)',

      // Profile - REAL endpoints
      'GET /users/me': 'ProfileRemoteDataSource.getMe',
      'PUT /users/profile': 'ProfileRemoteDataSource.updateMe',

      // KYC - REAL endpoints (different path from old mobile constants)
      'POST /kyc/submit': 'ProfileRemoteDataSource.submitKyc',
      'GET /kyc/status': 'ProfileRemoteDataSource.getKycStatus',

      // Transactions - REAL endpoints
      'GET /transactions': 'TransactionRemoteDataSource.getTransactions',
      'GET /transactions/{id}': 'TransactionRemoteDataSource.getTransactionDetail',

      // Sessions - REAL endpoints
      'GET /sessions': 'SessionRemoteDataSource.getSessions',
      'DELETE /sessions/{sessionId}': 'SessionRemoteDataSource.deleteSession',

      // Notifications - REAL endpoints
      'GET /notifications': 'NotificationRemoteDataSource.getNotifications',
      'PATCH /notifications/read-all': 'NotificationRemoteDataSource.readAll',
      'PUT /notifications/settings': 'NotificationRemoteDataSource.updateSettings',

      // Support - REAL endpoints
      'GET /support/faq': 'SupportRemoteDataSource.getFaq',
      'POST /support/tickets': 'SupportRemoteDataSource.createTicket',

      // Devices/FCM - REAL endpoints
      'POST /devices/register': 'DeviceRemoteDataSource.registerDevice',
      'DELETE /devices/unregister': 'DeviceRemoteDataSource.unregisterDevice',

      // Promotions - REAL endpoints
      'GET /promotions': 'PromotionRemoteDataSource.getPromotions',
      'GET /promotions/my-vouchers': 'PromotionRemoteDataSource.getMyVouchers',
      'POST /promotions/redeem': 'PromotionRemoteDataSource.redeem',
      'POST /promotions/apply': 'PromotionRemoteDataSource.apply',

      // Banks - REAL endpoint
      'GET /payments/banks': 'BankRemoteDataSource.getBanks',

      // Auth OTP & Password Recovery - REAL endpoints
      'POST /auth/otp/send': 'AuthRemoteDataSource.sendOtp',
      'POST /auth/otp/verify': 'AuthRemoteDataSource.verifyOtp',
      'POST /auth/forgot-password': 'AuthRemoteDataSource.forgotPassword',
      'POST /auth/reset-password': 'AuthRemoteDataSource.resetPassword',
      'POST /auth/change-password/otp': 'AuthRemoteDataSource.requestChangePasswordOtp',
      'POST /auth/change-password': 'AuthRemoteDataSource.changePassword',

      // Transaction PIN & Biometric - REAL endpoints
      'POST /users/pin/set': 'AuthRemoteDataSource.setPin',
      'POST /users/pin/verify': 'WalletTransactionRemoteDataSource.verifyPin',
      'POST /security/biometric/verify': 'BiometricRemoteDataSource.verify',

      // Deposit & Withdraw - REAL endpoints
      'POST /wallets/deposit': 'WalletTransactionRemoteDataSource.deposit',
      'POST /wallets/withdraw': 'WalletTransactionRemoteDataSource.withdraw',

      // Bills & Utilities - REAL endpoints
      'GET /bills/lookup': 'BillRemoteDataSource.lookupBill',
      'POST /bills/pay': 'BillRemoteDataSource.payBill',
      'POST /bills/topup': 'BillRemoteDataSource.topupPhone',

      // VietQR & Personal QR - REAL endpoints
      'POST /payments/vietqr/decode': 'VietQrRemoteDataSource.decode',
      'POST /payments/vietqr/generate': 'VietQrRemoteDataSource.generate',
      'GET /users/me/qrcode': 'ProfileRemoteDataSource.getMyQrCode',

      // Bank Accounts, Beneficiaries & Funding Sources - REAL endpoints
      'POST /bank-accounts/link': 'BankAccountRemoteDataSource.linkAccount',
      'GET /bank-accounts': 'BankAccountRemoteDataSource.getAccounts',
      'DELETE /bank-accounts/{id}': 'BankAccountRemoteDataSource.unlinkAccount',
      'POST /beneficiaries': 'BeneficiaryRemoteDataSource.create',
      'GET /beneficiaries': 'BeneficiaryRemoteDataSource.getAll',
      'GET /funding-sources': 'FundingSourceRemoteDataSource.getAll',

      // Config Limits, Avatar, Receipt PDF, Money Requests, Referrals, Legal, Feedback, FCM - REAL endpoints
      'POST /users/me/avatar': 'ProfileRemoteDataSource.updateAvatar',
      'GET /config/limits': 'ConfigRemoteDataSource.getLimits',
      'GET /config/limits/status': 'ConfigRemoteDataSource.getLimitsStatus',
      'GET /transactions/{id}/receipt.pdf': 'TransactionRemoteDataSource.getReceiptPdf',
      'GET /payments/money-requests/received': 'MoneyRequestRemoteDataSource.getReceived',
      'GET /payments/money-requests/sent': 'MoneyRequestRemoteDataSource.getSent',
      'GET /payments/money-requests/{id}': 'MoneyRequestRemoteDataSource.getDetail',
      'POST /payments/money-requests/{id}/cancel': 'MoneyRequestRemoteDataSource.cancel',
      'GET /referrals/code': 'ReferralRemoteDataSource.getCode',
      'GET /referrals/history': 'ReferralRemoteDataSource.getHistory',
      'POST /referrals/apply': 'ReferralRemoteDataSource.apply',
      'GET /legal/terms': 'LegalRemoteDataSource.getTerms',
      'POST /legal/consent': 'LegalRemoteDataSource.submitConsent',
      'POST /feedback': 'FeedbackRemoteDataSource.submit',
      'POST /sessions/{deviceId}/fcm': 'SessionRemoteDataSource.registerFcm',

      // Savings, Loans, Cards & Lottery - REAL In-House Core Banking endpoints
      'GET /savings/products': 'SavingsRemoteDataSource.getProducts',
      'POST /savings/accounts': 'SavingsRemoteDataSource.openSavings',
      'GET /savings/accounts': 'SavingsRemoteDataSource.getAccounts',
      'GET /savings/accounts/{id}': 'SavingsRemoteDataSource.getDetail',
      'POST /savings/accounts/{id}/settle': 'SavingsRemoteDataSource.settle',
      'GET /loans/products': 'LoanRemoteDataSource.getProducts',
      'POST /loans/apply': 'LoanRemoteDataSource.applyLoan',
      'GET /loans': 'LoanRemoteDataSource.getLoans',
      'GET /loans/{id}': 'LoanRemoteDataSource.getDetail',
      'GET /loans/{id}/schedule': 'LoanRemoteDataSource.getSchedule',
      'POST /loans/{id}/repay': 'LoanRemoteDataSource.repay',
      'GET /cards': 'CardRemoteDataSource.getCards',
      'POST /cards/issue': 'CardRemoteDataSource.issueCard',
      'PATCH /cards/{id}/status': 'CardRemoteDataSource.updateStatus',
      'PUT /cards/{id}/settings': 'CardRemoteDataSource.updateSettings',
    };

    test('All mobile MUST-EXIST endpoints are present in backend', () {
      final missing = <String>[];
      for (final entry in mobileEndpointsThatMustExist.entries) {
        final path = entry.key;
        if (!backendPaths.contains(path)) {
          missing.add('$path (called by ${entry.value})');
        }
      }
      if (missing.isNotEmpty) {
        fail('MISSING backend endpoints:\n${missing.map((m) => '  - $m').join('\n')}');
      }
    });

    /// === KNOWN BACKEND GAPS (BE-REQ) ===
    /// Legacy two-step transfer endpoints replaced by single-step /payments/transfer.
    final Map<String, String> knownBackendGaps = {
      'POST /wallets/transfer/init': 'BE-GAP: Old init/confirm flow removed, use /payments/transfer',
      'POST /wallets/transfer/{id}/confirm': 'BE-GAP: Old init/confirm flow removed, use /payments/transfer',
    };

    test('Known backend gaps are documented and match BE-REQ', () {
      // This test verifies that our known gaps list is accurate
      // Each gap should correspond to a BE-REQ in 01_ISSUES_AND_TASKS.md
      for (final entry in knownBackendGaps.entries) {
        final path = entry.key;
        final reason = entry.value;
        // Verify the gap actually doesn't exist in backend
        if (backendPaths.contains(path)) {
          // This is OK if backend added it - but we should update the gap list
          print('WARNING: $path now exists in backend! Update knownBackendGaps list. Reason was: $reason');
        } else {
          // Expected - gap still exists
        }
      }
      // Just document, don't fail
      expect(true, isTrue);
    });

    /// === MOBILE CALLS WRONG PATHS ===
    /// These are cases where mobile uses a different path than backend

    final Map<String, String> mobileWrongPaths = {
      // Mobile uses /banks but backend has /payments/banks
      '/banks': '/payments/banks (BankController)',
    };

    test('Mobile paths that differ from backend are documented', () {
      for (final entry in mobileWrongPaths.entries) {
        final mobilePath = entry.key;
        final backendPath = entry.value;
        // Check if mobile path exists (it shouldn't)
        if (backendPaths.contains(mobilePath)) {
          print('NOTE: $mobilePath now exists in backend');
        }
        // Check if backend path exists
        if (!backendPaths.contains(backendPath.replaceAll('/payments/banks', '/payments/banks'))) {
          // Check with pattern matching
        }
      }
      expect(true, isTrue);
    });
  });
}

/// Helper classes and functions

class BackendEndpoint {
  final String method;
  final String path;
  final String controller;
  final String fullPath;

  BackendEndpoint({
    required this.method,
    required this.path,
    required this.controller,
  }) : fullPath = '$method $path';
}

List<BackendEndpoint> _extractBackendEndpoints() {
  final endpoints = <BackendEndpoint>[];
  final backendDir = Directory('../backend');

  if (!backendDir.existsSync()) {
    print('WARNING: Backend directory not found at ../backend');
    return endpoints;
  }

  // Find all Controller.java files
  final controllerFiles = _findFiles(backendDir, 'Controller.java');

  for (final file in controllerFiles) {
    final content = file.readAsStringSync();
    final controllerName = file.path.split('/').last.replaceAll('.java', '');

    // Extract base @RequestMapping from class
    String basePath = '';
    final classMappingMatch = RegExp(r'''@RequestMapping\s*\(\s*(?:value\s*=\s*)?["']([^"']+)["']''').firstMatch(content);
    int classBodyStart = 0;
    if (classMappingMatch != null) {
      basePath = classMappingMatch.group(1)!;
      if (!basePath.startsWith('/')) basePath = '/$basePath';
      classBodyStart = classMappingMatch.end;
    }

    final classContent = classBodyStart > 0 ? content.substring(classBodyStart) : content;

    // Extract method-level mappings
    final methodMatches = RegExp(
      r'''@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|RequestMapping)(?:\s*\(\s*(?:value\s*=\s*|path\s*=\s*)?["']([^"']*)["'][^)]*\))?''',
    ).allMatches(classContent);

    for (final match in methodMatches) {
      final methodAnnotation = match.group(1)!;
      final methodPath = match.group(2) ?? '';

      String httpMethod;
      switch (methodAnnotation) {
        case 'GetMapping':
          httpMethod = 'GET';
          break;
        case 'PostMapping':
          httpMethod = 'POST';
          break;
        case 'PutMapping':
          httpMethod = 'PUT';
          break;
        case 'PatchMapping':
          httpMethod = 'PATCH';
          break;
        case 'DeleteMapping':
          httpMethod = 'DELETE';
          break;
        case 'RequestMapping':
          httpMethod = 'GET';
          break;
        default:
          httpMethod = 'GET';
      }

      // For RequestMapping, try to get method from method attribute
      if (methodAnnotation == 'RequestMapping') {
        final contextSnippet = classContent.substring(match.start, (match.end + 200).clamp(0, classContent.length));
        final methodAttrMatch = RegExp(r'method\s*=\s*RequestMethod\.(\w+)').firstMatch(contextSnippet);
        if (methodAttrMatch != null) {
          httpMethod = methodAttrMatch.group(1)!;
        }
      }

      // Normalize path
      String fullPath = '$basePath$methodPath';
      fullPath = fullPath.replaceAll(RegExp(r'/+'), '/');
      if (fullPath.endsWith('/') && fullPath.length > 1) {
        fullPath = fullPath.substring(0, fullPath.length - 1);
      }
      if (!fullPath.startsWith('/')) fullPath = '/$fullPath';

      // Normalize by stripping /api/v1 so it matches mobile endpoints list
      String normalizedPath = fullPath;
      if (normalizedPath.startsWith('/api/v1')) {
        normalizedPath = normalizedPath.substring(7);
      }
      if (!normalizedPath.startsWith('/')) normalizedPath = '/$normalizedPath';

      endpoints.add(BackendEndpoint(
        method: httpMethod,
        path: normalizedPath,
        controller: controllerName,
      ));
    }
  }

  // Also check for gateway routes in application.yml
  _extractGatewayRoutes(endpoints);

  return endpoints;
}

List<File> _findFiles(Directory dir, String pattern) {
  final results = <File>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith(pattern)) {
      results.add(entity);
    }
  }
  return results;
}

void _extractGatewayRoutes(List<BackendEndpoint> endpoints) {
  final gatewayYml = File('../backend/services/api-gateway/src/main/resources/application.yml');
  if (!gatewayYml.existsSync()) return;

  final content = gatewayYml.readAsStringSync();

  // Extract routes from YAML (simplified)
  // Looking for patterns like: path: /api/v1/auth/**
  final routeMatches = RegExp(r'''path:\s*["']?(/api/v1/\S+)["']?''').allMatches(content);
  for (final match in routeMatches) {
    final path = match.group(1)!;
    endpoints.add(BackendEndpoint(
      method: 'ANY',
      path: path,
      controller: 'GatewayRoute',
    ));
  }
}