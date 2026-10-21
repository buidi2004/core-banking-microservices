import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/ekyc_screens.dart';

void main() {
  group('EKycScreen Step-by-Step Flow Tests', () {
    Widget createWidgetUnderTest() {
      final router = GoRouter(
        initialLocation: '/ekyc',
        routes: [
          GoRoute(
            path: '/ekyc',
            builder: (context, state) => const EKycScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Scaffold(body: Text('Profile Screen')),
          ),
          GoRoute(
            path: '/profile/nfc-reader',
            builder: (context, state) => const Scaffold(body: Text('NFC Reader Screen')),
          ),
          GoRoute(
            path: '/profile/kyc-level',
            builder: (context, state) => const Scaffold(body: Text('KYC Level Screen')),
          ),
          GoRoute(
            path: '/profile/identity-document',
            builder: (context, state) => const Scaffold(body: Text('Identity Document Screen')),
          ),
          GoRoute(
            path: '/profile/digital-signature',
            builder: (context, state) => const Scaffold(body: Text('Digital Signature Screen')),
          ),
        ],
      );

      return MaterialApp.router(
        routerConfig: router,
      );
    }

    testWidgets('EKycScreen cycles from Step 1 to Step 4 Success and renders all actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Step 1: Front ID
      expect(find.text('Xác Thực eKYC (Bước 1/3)'), findsOneWidget);
      expect(find.text('Chụp mặt trước CCCD gắn chip'), findsOneWidget);

      // Advance to Step 2: Back ID
      await tester.tap(find.text('Chụp ảnh & Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Xác Thực eKYC (Bước 2/3)'), findsOneWidget);
      expect(find.text('Chụp mặt sau CCCD gắn chip'), findsOneWidget);

      // Advance to Step 3: Face Liveness
      await tester.tap(find.text('Chụp ảnh & Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Xác Thực eKYC (Bước 3/3)'), findsOneWidget);
      expect(find.text('Quét khuôn mặt (Face Liveness)'), findsOneWidget);
      expect(find.text('Hoàn tất quét khuôn mặt'), findsOneWidget);

      // Complete to Step 4: Success View
      await tester.tap(find.text('Hoàn tất quét khuôn mặt'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Xác Thực eKYC'), findsOneWidget);
      expect(find.text('Xác Thực eKYC Thành Công!'), findsOneWidget);
      expect(find.text('Về hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Về màn hình chính'), findsOneWidget);
      expect(find.text('Xem bảng hạn mức chi tiêu mới (Kyc Level)'), findsOneWidget);
      expect(find.text('Quản lý thông tin giấy tờ CCCD đã duyệt'), findsOneWidget);
      expect(find.text('Kích hoạt Chữ ký số Smart OTP PKI'), findsOneWidget);
    });

    testWidgets('EKycScreen back button steps back properly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Chụp ảnh & Tiếp tục'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Xác Thực eKYC (Bước 2/3)'), findsOneWidget);

      // Tap Back button in AppBar
      await tester.tap(find.byIcon(CupertinoIcons.chevron_back));
      await tester.pumpAndSettle();

      // Should be back to Step 1
      expect(find.text('Xác Thực eKYC (Bước 1/3)'), findsOneWidget);
    });

    testWidgets('EKycScreen NFC modal opens and navigates to NFC reader', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap NFC icon button in AppBar
      await tester.tap(find.byTooltip('Đọc NFC'));
      await tester.pumpAndSettle();

      expect(find.text('Đọc Chip CCCD Qua Sóng NFC'), findsOneWidget);
      expect(find.text('Bắt đầu quét NFC'), findsOneWidget);

      // Tap start NFC scan
      await tester.tap(find.text('Bắt đầu quét NFC'));
      await tester.pumpAndSettle();

      // Navigates to NFC reader
      expect(find.text('NFC Reader Screen'), findsOneWidget);
    });
  });
}
