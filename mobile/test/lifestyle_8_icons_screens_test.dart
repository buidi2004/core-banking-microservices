import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/all_services_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/data_topup_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/digital_flight_ticket_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/game_card_data_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/imedia_flight_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/van_so_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/vietlott_screen.dart';
import 'package:sen_hong_bank/presentation/screens/lifestyle/vua_xo_so_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('8 Lifestyle Dedicated Screens Tests', () {
    testWidgets('1. VuaXoSoScreen renders and allows ticket check and simulation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: VuaXoSoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vua Xổ Số'), findsOneWidget);
      expect(find.text('GIẢI ĐẶC BIỆT'), findsOneWidget);
      expect(find.text('Dò vé số thần tốc'), findsOneWidget);
      expect(find.text('Quay thử lồng cầu may mắn'), findsOneWidget);
    });

    testWidgets('2. VietlottScreen renders, quick pick, and displays balls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: VietlottScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vé Số Vietlott'), findsOneWidget);
      expect(find.text('JACKPOT TÍCH LŨY'), findsOneWidget);
      expect(find.text('Tự chọn'), findsOneWidget);
    });

    testWidgets('3. DataTopupScreen renders data packages and phone input', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: DataTopupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Data 4G / Nạp tiền'), findsOneWidget);
      expect(find.text('Gói cước Data 4G/5G'), findsOneWidget);
      expect(find.text('Nạp tiền điện thoại'), findsOneWidget);
      expect(find.text('ST90N'), findsOneWidget);
    });

    testWidgets('4. DigitalFlightTicketScreen renders e-ticket and flights', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DigitalFlightTicketScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vé Máy Bay Số'), findsOneWidget);
      expect(find.text('Săn vé số điện tử'), findsOneWidget);
      expect(find.text('Vé của tôi (E-Ticket)'), findsOneWidget);
      expect(find.text('SGN'), findsWidgets);
      expect(find.text('HAN'), findsWidgets);
    });

    testWidgets('5. ImediaFlightScreen renders partner deals and extras', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ImediaFlightScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vé máy bay'), findsOneWidget);
      expect(find.text('ƯU ĐÃI ĐỘC QUYỀN iMEDIA'), findsOneWidget);
      expect(find.text('Tiện ích chuyến bay cộng thêm'), findsOneWidget);
    });

    testWidgets('6. GameCardDataScreen renders publishers and denominations', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GameCardDataScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Data 4G / Thẻ Game'), findsOneWidget);
      expect(find.text('Garena'), findsOneWidget);
      expect(find.text('Zing Xu'), findsOneWidget);
      expect(find.text('Mua thẻ game'), findsOneWidget);
    });

    testWidgets('7. VanSoScreen renders feng shui energy and I-Ching toss', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VanSoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Vận Số & Phong Thủy'), findsOneWidget);
      expect(find.text('LỊCH VẠN NIÊN HÔM NAY'), findsOneWidget);
      expect(find.text('Bản Mệnh & Số Tài Lộc'), findsOneWidget);
      expect(find.text('Trực ngày'), findsOneWidget);
    });

    testWidgets('8. AllServicesScreen renders categorized services and search', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AllServicesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tất Cả Dịch Vụ'), findsOneWidget);
      expect(find.text('Mua sắm - Giải trí - Đầu tư'), findsOneWidget);
      expect(find.text('Vua Xổ Số'), findsOneWidget);
      expect(find.text('Vé số Vietlott'), findsOneWidget);
    });
  });
}
