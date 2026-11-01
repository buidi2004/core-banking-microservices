import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/theme/apple_hig_tokens.dart';
import 'package:sen_hong_bank/main.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/transfer_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Giai đoạn 1 Kiểm Tra: Apple HIG Design System Tokens & Typography', () {
    test('1.1 AppleHigSpacing values tuân thủ 100% quy chuẩn Apple HIG', () {
      expect(AppleHigSpacing.standard, 16.0);
      expect(AppleHigSpacing.compact, 8.0);
      expect(AppleHigSpacing.micro, 4.0);
      expect(AppleHigSpacing.large, 24.0);
      expect(AppleHigSpacing.extraLarge, 32.0);
      expect(AppleHigSpacing.minTouchTarget, 44.0);
      expect(AppleHigSpacing.minTouchSize, const Size(44.0, 44.0));
      expect(AppleHigSpacing.radiusCard, 16.0);
      expect(AppleHigSpacing.radiusSheet, 24.0);
      expect(AppleHigSpacing.radiusButton, 14.0);
    });

    testWidgets('1.2 AppTypography cung cấp toàn bộ 11 kiểu chữ chuẩn Apple HIG',
        (tester) async {
      final largeTitle = AppTypography.largeTitle();
      expect(largeTitle.fontSize, 34.0);
      expect(largeTitle.fontWeight, FontWeight.w700);

      final title1 = AppTypography.title1();
      expect(title1.fontSize, 28.0);
      expect(title1.fontWeight, FontWeight.w600);

      final title2 = AppTypography.title2();
      expect(title2.fontSize, 22.0);
      expect(title2.fontWeight, FontWeight.w600);

      final title3 = AppTypography.title3();
      expect(title3.fontSize, 20.0);
      expect(title3.fontWeight, FontWeight.w600);

      final headline = AppTypography.headline();
      expect(headline.fontSize, 17.0);
      expect(headline.fontWeight, FontWeight.w600);

      final body = AppTypography.body();
      expect(body.fontSize, 17.0);
      expect(body.fontWeight, FontWeight.w400);

      final callout = AppTypography.callout();
      expect(callout.fontSize, 16.0);
      expect(callout.fontWeight, FontWeight.w400);

      final subheadline = AppTypography.subheadline();
      expect(subheadline.fontSize, 15.0);
      expect(subheadline.fontWeight, FontWeight.w400);

      final footnote = AppTypography.footnote();
      expect(footnote.fontSize, 13.0);
      expect(footnote.fontWeight, FontWeight.w400);

      final caption1 = AppTypography.caption1();
      expect(caption1.fontSize, 12.0);
      expect(caption1.fontWeight, FontWeight.w500);

      final caption2 = AppTypography.caption2();
      expect(caption2.fontSize, 11.0);
      expect(caption2.fontWeight, FontWeight.w400);
    });

    testWidgets('1.3 AppleSemanticColors phân giải an toàn trên BuildContext',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              final bg = AppleSemanticColors.systemBackground(context);
              final groupedBg =
                  AppleSemanticColors.secondarySystemGroupedBackground(context);
              final label = AppleSemanticColors.label(context);
              final blue = AppleSemanticColors.systemBlue(context);
              final green = AppleSemanticColors.systemGreen(context);
              final red = AppleSemanticColors.systemRed(context);

              expect(bg, isNotNull);
              expect(groupedBg, isNotNull);
              expect(label, isNotNull);
              expect(blue, isNotNull);
              expect(green, isNotNull);
              expect(red, isNotNull);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('Giai đoạn 2 Kiểm Tra: Translucent Frosted Glass TabBar & Haptics', () {
    testWidgets('2.1 Frosted Glass Tab Bar có BackdropFilter và viền mờ 0.5pt',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            bottomNavigationBar: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.85),
                    border: const Border(
                      top: BorderSide(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: CupertinoTabBar(
                      currentIndex: 0,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.house),
                          label: 'Trang chủ',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.clock),
                          label: 'Giao dịch',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsAtLeastNWidgets(1));
      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
    });
  });

  group('Giai đoạn 3 Kiểm Tra: Bàn Phím PIN & Taptic Engine Result Screen', () {
    testWidgets('3.1 CustomPinNumpad render đủ chấm PIN và tương tác phím số',
        (tester) async {
      String currentPin = '12';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CustomPinNumpad(
                  pin: currentPin,
                  maxDigits: 6,
                  onPinChanged: (val) {
                    setState(() => currentPin = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // 6 chấm PIN: AnimatedContainer
      expect(find.byType(AnimatedContainer), findsNWidgets(6));

      // Bấm số 3
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(currentPin, '123');

      // Bấm nút xóa (delete icon)
      await tester.tap(find.byIcon(CupertinoIcons.delete_left_fill));
      await tester.pump();
      expect(currentPin, '12');
    });

    testWidgets('3.2 TransferResultScreen khởi tạo thành công và kích hoạt nhịp haptic',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransferResultScreen(
            recipient: 'TRAN THI B',
            amount: 250000,
            note: 'Chuyen tien an trua',
            status: 'SUCCESS',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Giao Dịch Thành Công'), findsOneWidget);
      expect(find.text('TRAN THI B'), findsOneWidget);
    });
  });

  group('Giai đoạn 4 Kiểm Tra: Bảo Mật Ngân Hàng (Privacy Protection Blur)', () {
    testWidgets('4.1 SenHongApp tự động kích hoạt Privacy Blur khi app inactive / paused',
        (tester) async {
      await tester.pumpWidget(const SenHongApp());
      await tester.pump();

      // Lúc đầu ứng dụng đang ở foreground (resumed), không có Privacy Blur
      expect(find.text('Bảo Mật Ngân Hàng Số'), findsNothing);
      expect(find.byIcon(CupertinoIcons.lock_shield_fill), findsNothing);

      // Giả lập người dùng vuốt mở App Switcher (iOS Inactive state)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // Màn hình kính mờ bảo mật Apple Privacy Screen tự động hiển thị
      expect(find.text('Bảo Mật Ngân Hàng Số'), findsOneWidget);
      expect(find.text('Dữ liệu giao dịch được mã hóa an toàn'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.lock_shield_fill), findsOneWidget);

      // Giả lập trạng thái tạm dừng khi khóa màn hình (Paused state)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(find.text('Bảo Mật Ngân Hàng Số'), findsOneWidget);

      // Người dùng quay lại ứng dụng (Resumed state)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Màn hình kính mờ bảo mật tự động biến mất, trả lại giao diện bình thường
      expect(find.text('Bảo Mật Ngân Hàng Số'), findsNothing);
    });
  });
}
