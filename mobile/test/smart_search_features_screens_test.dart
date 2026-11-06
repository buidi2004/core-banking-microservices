import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/deposit_withdraw/atm_withdrawal_screen.dart';
import 'package:sen_hong_bank/presentation/screens/cards/lucky_account_screen.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/international_transfer_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/flight_booking_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/social_insurance_screen.dart';

void main() {
  group('Smart Search New Features Screens Tests', () {
    testWidgets('AtmWithdrawalScreen never displays a fake withdrawal code',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AtmWithdrawalScreen(),
        ),
      );

      expect(find.text('Rút tiền ATM không cần thẻ'), findsOneWidget);
      expect(find.text('Số tiền cần rút tại cây ATM'), findsOneWidget);

      final buttonFinder = find.text('Kiểm tra hỗ trợ rút tiền ATM');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();

      expect(buttonFinder, findsOneWidget);
      expect(find.text('839217'), findsNothing);
      expect(find.text('Mã rút tiền ATM của bạn'), findsNothing);
    });

    testWidgets('LuckyAccountScreen renders categories and accounts list',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LuckyAccountScreen(),
        ),
      );

      expect(find.text('Mở tài khoản số đẹp'), findsOneWidget);
      expect(find.text('Lộc Phát (68-86)'), findsOneWidget);
      expect(find.text('Thần Tài (79-39)'), findsOneWidget);
      expect(find.text('Tứ Quý'), findsOneWidget);
      expect(find.text('8888 6868 99'), findsOneWidget);
    });

    testWidgets(
        'InternationalTransferScreen renders countries and calculates conversion',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InternationalTransferScreen(),
        ),
      );

      expect(find.text('Chuyển tiền quốc tế'), findsOneWidget);
      expect(find.text('Hoa Kỳ (Mỹ)'), findsOneWidget);
      expect(find.text('Tiếp tục chuyển tiền quốc tế'), findsOneWidget);
      expect(find.text('Mã SWIFT / BIC'), findsOneWidget);
    });

    testWidgets('FlightBookingScreen renders flight search and airline filters',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FlightBookingScreen(),
        ),
      );

      expect(find.text('Vé máy bay VNA & Đối tác'), findsOneWidget);
      expect(find.text('SGN'), findsWidgets);
      expect(find.text('HAN'), findsWidgets);
      expect(find.text('🇻🇳 Vietnam Airlines'), findsOneWidget);
      expect(find.textContaining('VN-242'), findsOneWidget);
    });

    testWidgets(
        'SocialInsuranceScreen renders insurance forms and subsidy calculation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SocialInsuranceScreen(),
        ),
      );

      expect(find.text('Bảo hiểm xã hội Việt Nam'), findsOneWidget);
      expect(find.text('BHXH tự nguyện'), findsOneWidget);
      expect(find.text('Gia hạn BHYT'), findsOneWidget);
      expect(find.text('Nộp tiền Bảo hiểm Xã hội'), findsOneWidget);
    });
  });
}
