import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/presentation/routes/app_router.dart';

void main() {
  test('All required routes exist in appRouter', () {
    final expectedPaths = [
      '/splash',
      '/',
      '/history',
      '/promotions',
      '/more',
      '/auth/login',
      '/auth/register',
      '/auth/otp',
      '/auth/set-pin',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/forgot-pin',
      '/auth/terms',
      '/transfer',
      '/transfer/amount',
      '/transfer/confirm',
      '/transfer/2fa-otp',
      '/transfer/result',
      '/transfer/request',
      '/beneficiaries',
      '/scan-qr',
      '/my-qr',
      '/deposit',
      '/deposit/confirm',
      '/withdraw',
      '/withdraw/confirm',
      '/history/detail',
      '/bills',
      '/bills/input',
      '/bills/confirm',
      '/bills/phone-recharge',
      '/bills/lottery',
      '/bills/savings',
      '/bills/quick-loan',
      '/cards',
      '/payment-methods',
      '/bank-cards',
      '/profile',
      '/profile/identity',
      '/profile/kyc-level',
      '/profile/ekyc',
      '/profile/digital-signature',
      '/profile/email-settings',
      '/settings/security',
      '/settings/devices',
      '/settings',
      '/settings/config',
      '/notifications',
      '/search',
      '/referral',
      '/support/help-center',
      '/help-center',
      '/support/live-chat',
      '/live-chat',
      '/qr-scanner',
      '/savings',
    ];

    final registeredPaths = <String>{};

    void collectRoutes(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) {
          registeredPaths.add(r.path);
          if (r.routes.isNotEmpty) {
            collectRoutes(r.routes);
          }
        } else if (r is ShellRoute) {
          collectRoutes(r.routes);
        } else if (r is StatefulShellRoute) {
          for (final branch in r.branches) {
            collectRoutes(branch.routes);
          }
        }
      }
    }

    collectRoutes(appRouter.configuration.routes);

    for (final path in expectedPaths) {
      expect(
        registeredPaths.contains(path),
        isTrue,
        reason: 'Route $path must be registered in appRouter',
      );
    }
    expect(registeredPaths.length, greaterThanOrEqualTo(50));
  });

  test('All route paths resolve properly via GoRouter matching engine', () {
    final pathsToTest = [
      '/',
      '/history',
      '/promotions',
      '/more',
      '/auth/login',
      '/auth/register',
      '/auth/otp?phone=0901234567',
      '/auth/set-pin',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/forgot-pin',
      '/auth/terms',
      '/transfer',
      '/transfer/amount?recipient=0901234567',
      '/transfer/confirm',
      '/transfer/2fa-otp',
      '/transfer/result',
      '/transfer/request',
      '/beneficiaries',
      '/scan-qr',
      '/qr-scanner',
      '/my-qr',
      '/deposit',
      '/deposit/confirm?amount=100000&source=VCB',
      '/withdraw',
      '/withdraw/confirm?amount=100000&bank=TCB',
      '/history/detail?id=1&title=test&amount=10000',
      '/bills',
      '/bills/input?service=ELECTRICITY',
      '/bills/confirm',
      '/bills/phone-recharge',
      '/bills/lottery',
      '/bills/savings',
      '/savings',
      '/bills/quick-loan',
      '/cards',
      '/payment-methods',
      '/bank-cards',
      '/profile',
      '/profile/identity',
      '/profile/kyc-level',
      '/profile/ekyc',
      '/profile/digital-signature',
      '/profile/email-settings',
      '/settings/security',
      '/settings/devices',
      '/settings',
      '/settings/config',
      '/notifications',
      '/search',
      '/referral',
      '/support/help-center',
      '/help-center',
      '/support/live-chat',
      '/live-chat',
    ];

    for (final path in pathsToTest) {
      final matches = appRouter.configuration.findMatch(Uri.parse(path));
      expect(matches.isNotEmpty, isTrue, reason: 'Path $path must resolve in GoRouter');
    }
  });
}
