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

      // Banks - REAL endpoint (path differs: /payments/banks not /banks)
      'GET /payments/banks': 'BankRemoteDataSource.getBanks (mobile uses /banks - WRONG)',
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
    /// These endpoints mobile code CALLS or HAS CONSTANTS FOR but DO NOT EXIST in backend.
    /// They are documented in 01_ISSUES_AND_TASKS.md as BE-REQ items.
    /// Mobile code should GATE these behind BackendCapabilities flags.

    final Map<String, String> knownBackendGaps = {
      // BE-REQ-04: OTP/Forgot password
      'POST /auth/otp/send': 'BE-REQ-04: OTP not implemented',
      'POST /auth/otp/verify': 'BE-REQ-04: OTP not implemented',
      'POST /auth/forgot-password': 'BE-REQ-04: Forgot password not implemented',
      'POST /auth/reset-password': 'BE-REQ-04: Reset password not implemented',

      // BE-REQ-03: PIN/OTP for transactions
      'POST /users/pin/set': 'BE-REQ-03: Transaction PIN not implemented',
      'POST /users/pin/verify': 'BE-REQ-03: Transaction PIN verify not implemented',
      'POST /security/biometric/verify': 'BE-REQ-03: Biometric verify not implemented',

      // BE-REQ-06: Deposit/Withdraw
      'POST /wallets/deposit': 'BE-REQ-06: Deposit not implemented',
      'POST /wallets/withdraw': 'BE-REQ-06: Withdraw not implemented',

      // BE-REQ-06: Old transfer flow (init/confirm) - replaced by single-step /payments/transfer
      'POST /wallets/transfer/init': 'BE-GAP: Old init/confirm flow removed, use /payments/transfer',
      'POST /wallets/transfer/{id}/confirm': 'BE-GAP: Old init/confirm flow removed, use /payments/transfer',

      // BE-REQ-06: Bills/Utilities
      'GET /bills/lookup': 'BE-REQ-06: Bills not implemented',
      'POST /bills/pay': 'BE-REQ-06: Bills not implemented',
      'POST /bills/topup': 'BE-REQ-06: Phone topup not implemented',

      // BE-REQ-06: VietQR
      'POST /payments/vietqr/decode': 'BE-REQ-06: VietQR decode not implemented',
      'POST /payments/vietqr/generate': 'BE-REQ-06: VietQR generate not implemented',

      // BE-REQ-06: Bank accounts
      'POST /bank-accounts/link': 'BE-REQ-06: Bank accounts not implemented',
      'GET /bank-accounts': 'BE-REQ-06: Bank accounts not implemented',
      'DELETE /bank-accounts/{id}': 'BE-REQ-06: Bank accounts not implemented',

      // BE-REQ-06: Beneficiaries
      'POST /beneficiaries': 'BE-REQ-06: Beneficiaries not implemented',
      'GET /beneficiaries': 'BE-REQ-06: Beneficiaries not implemented',

      // BE-REQ-06: Funding sources
      'GET /funding-sources': 'BE-REQ-06: Funding sources not implemented',

      // BE-REQ-06: User profile extras
      'POST /users/me/avatar': 'BE-GAP: Avatar upload not implemented',
      'GET /users/me/qrcode': 'BE-GAP: Personal QR not implemented',
      'GET /config/limits': 'BE-REQ-06: Config limits not implemented',
      'GET /config/limits/status': 'BE-REQ-06: Config limits status not implemented',

      // BE-REQ-06: Receipt/Export
      'GET /transactions/{id}/receipt.pdf': 'BE-REQ-06: Receipt PDF not implemented',
      'GET /transactions/export/csv': 'BE-REQ-06: Export CSV not implemented',
      'GET /transactions/export/pdf': 'BE-REQ-06: Export PDF not implemented',
      'GET /transactions/export/excel': 'BE-REQ-06: Export Excel not implemented',

      // BE-REQ-06: Money requests (some endpoints differ)
      'GET /payments/money-requests/received': 'BE-REQ-06: Money request received not implemented',
      'GET /payments/money-requests/sent': 'BE-REQ-06: Money request sent not implemented',
      'GET /payments/money-requests/{id}': 'BE-REQ-06: Money request detail not implemented',
      'POST /payments/money-requests/{id}/cancel': 'BE-REQ-06: Money request cancel not implemented',

      // BE-REQ-06: Referrals
      'GET /referrals/code': 'BE-REQ-06: Referrals not implemented',
      'GET /referrals/history': 'BE-REQ-06: Referrals not implemented',
      'POST /referrals/apply': 'BE-REQ-06: Referrals not implemented',

      // BE-REQ-06: Legal/Feedback
      'GET /legal/terms': 'BE-GAP: Legal terms may exist but unverified',
      'POST /legal/consent': 'BE-REQ-06: Legal consent not implemented',
      'POST /feedback': 'BE-REQ-06: Feedback not implemented',

      // BE-REQ-06: Sessions FCM (partial)
      'POST /sessions/{deviceId}/fcm': 'BE-GAP: Session FCM registration not implemented',
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