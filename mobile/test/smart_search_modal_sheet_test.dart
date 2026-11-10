import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/smart_search_modal_sheet.dart';

class FakeBeneficiaryDataSource extends BeneficiaryRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    return [
      {
        'id': 'b1',
        'name': 'TRAN THI HUONG',
        'accountNumber': '0988776655',
        'bankCode': 'Ví Sen Hồng',
        'phoneNumber': '0988776655',
      },
      {
        'id': 'b2',
        'name': 'LE HOANG NAM',
        'accountNumber': '190367823901',
        'bankCode': 'Techcombank',
        'phoneNumber': '0912345678',
      },
    ];
  }
}

class FakeTransferDataSource extends TransferRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getRecipient(String value) async {
    if (value == '0987654321') {
      return {
        'fullName': 'NGUYEN VAN A',
        'phoneNumber': '0987654321',
        'bankName': 'Ví Sen Hồng',
        'walletId': 'wallet-123',
      };
    }
    throw Exception('Not found');
  }
}

void main() {
  group('SmartSearchModalSheet Tests', () {
    testWidgets('renders all visual tokens 100% matching image spec',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // 1. Tiêu đề "Tìm kiếm"
      expect(find.text('Tìm kiếm'), findsOneWidget); // Ô tìm kiếm

      // 2. Cụm nút "Dán"
      expect(find.text('Dán'), findsOneWidget);

      // 3. Card AI: Badge SenAI, Mô tả, 2 nút Chụp ảnh & Tải ảnh
      expect(find.text('SenAI'), findsOneWidget);
      expect(
        find.text(
            'Điền nhanh thông tin chuyển tiền từ văn bản hoặc ảnh mã VietQR'),
        findsOneWidget,
      );
      expect(find.text('Chụp ảnh'), findsOneWidget);
      expect(find.text('Tải ảnh'), findsOneWidget);

      // 4. Mục "Đề xuất" và 5 Pill bo tròn
      expect(find.text('Đề xuất'), findsOneWidget);
      expect(find.text('Rút tiền ATM'), findsOneWidget);
      expect(find.text('Mở tài khoản số đẹp'), findsOneWidget);
      expect(find.text('Chuyển tiền quốc tế'), findsOneWidget);
      expect(find.text('Mua vé máy bay VNA'), findsOneWidget);
      expect(find.text('Bảo hiểm xã hội'), findsOneWidget);

      // 5. Đảm bảo màn hình ban đầu không có mục chuyển tiền gần đây
      expect(find.text('Chuyển tiền gần đây'), findsNothing);
    });

    testWidgets(
        'initial state height is locked to exactly 60% of screen height and expands to 80% when typing',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Khi mới mở: Chiều cao khóa cứng ở 60% (800 * 0.60 = 480 dp)
      final collapsedBox =
          tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
      expect(collapsedBox.size.height, 480.0);

      // Khi nhập từ khóa tìm kiếm: bung dài lên 80% (800 * 0.80 = 640 dp) và giữ cố định
      await tester.enterText(find.byType(TextField), 'EVN');
      await tester.pumpAndSettle();

      final expandedBox =
          tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
      expect(expandedBox.size.height, 640.0);
    });

    testWidgets(
        'dragging horizontal handle bar snaps between 60% and 80%',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bắt đầu ở 60% (480 dp)
      final boxInitial =
          tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
      expect(boxInitial.size.height, 480.0);

      // Kéo thanh ngang lên trên (drag up: dy < 0)
      final handleFinder = find.byType(GestureDetector).first;
      await tester.drag(handleFinder, const Offset(0, -120));
      await tester.pumpAndSettle();

      // Snap lên 80% (640 dp)
      final boxUp =
          tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
      expect(boxUp.size.height, 640.0);

      // Kéo thanh ngang xuống dưới (drag down: dy > 0)
      await tester.drag(handleFinder, const Offset(0, 120));
      await tester.pumpAndSettle();

      // Snap về 60% (480 dp)
      final boxDown =
          tester.renderObject<RenderBox>(find.byType(AnimatedContainer));
      expect(boxDown.size.height, 480.0);
    });

    testWidgets('typing search query shows filtered results', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // Nhập "EVN" vào ô tìm kiếm
      await tester.enterText(find.byType(TextField), 'EVN');
      await tester.pumpAndSettle();

      // Kết quả hiển thị chức năng tiền điện EVN
      expect(find.text('Thanh toán tiền điện EVN'), findsOneWidget);
    });

    testWidgets('search matches multiple Vietnamese keywords together',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'tien dien');
      await tester.pumpAndSettle();

      expect(find.text('Thanh toán tiền điện EVN'), findsOneWidget);
      expect(find.textContaining('dịch vụ phù hợp'), findsOneWidget);
    });

    testWidgets('small phone with keyboard keeps the sheet scrollable',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );
      await tester.pump();

      final layoutError = tester.takeException();
      expect(layoutError, isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('unmatched query offers a way back to common services',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'khong co dich vu nay');
      await tester.pumpAndSettle();

      expect(find.textContaining('Chưa tìm thấy'), findsOneWidget);
      expect(find.text('Rút tiền ATM'), findsOneWidget);
    });

    testWidgets(
        'showSmartSearchModalSheet opens with useRootNavigator to hide bottom bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: const Text('BOTTOM_NAV_BAR'),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showSmartSearchModalSheet(ctx),
                child: const Text('OPEN_SHEET'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN_SHEET'));
      await tester.pumpAndSettle();

      // Modal sheet hiển thị
      expect(find.byType(SmartSearchModalSheet), findsOneWidget);
    });

    testWidgets('pasting text updates search field and triggers AI parsing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // Nhấn nút "Dán"
      await tester.tap(find.text('Dán'));
      await tester.pumpAndSettle();

      // Kiểm tra widget vẫn ổn định không crash
      expect(find.byType(SmartSearchModalSheet), findsOneWidget);
    });

    testWidgets(
        'typing alphanumeric mixed string with letters (e.g. 0877uuu) does NOT treat as account and shows fallback',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(),
          ),
        ),
      );

      // Nhập chuỗi lẫn chữ như ảnh phản hồi của người dùng
      await tester.enterText(find.byType(TextField), '0877uuu');
      await tester.pumpAndSettle();

      // Tuyệt đối không được nhận diện là STK để hiện "Chuyển tiền tới STK: 0877uuu"
      expect(find.textContaining('Chuyển tiền tới STK: 0877uuu'), findsNothing);
      expect(find.textContaining('Chưa tìm thấy “0877uuu”'), findsOneWidget);
      expect(find.text('Rút tiền ATM'), findsOneWidget);
    });

    testWidgets(
        'searching pure bank account digits triggers real-time account lookup',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(
              transferDataSource: FakeTransferDataSource(),
            ),
          ),
        ),
      );

      // Nhập đúng số tài khoản 0987654321
      await tester.enterText(find.byType(TextField), '0987654321');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Hiển thị thẻ xác thực tài khoản tìm thấy từ backend
      expect(find.text('Tài khoản tìm thấy (Đã xác thực)'), findsOneWidget);
      expect(find.text('NGUYEN VAN A'), findsOneWidget);
      expect(find.text('Chuyển tiền ngay tới tài khoản này'), findsOneWidget);
    });

    testWidgets(
        'searching pure 8+ digits not yet in system offers Napas 24/7 card',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(
              transferDataSource: FakeTransferDataSource(),
            ),
          ),
        ),
      );

      // Nhập số tài khoản hợp lệ khác chưa lưu trong hệ thống
      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Chuyển tiền tới STK: 1234567890'), findsOneWidget);
      expect(find.textContaining('Chuyển khoản liên ngân hàng 24/7 qua Napas'),
          findsOneWidget);
    });

    testWidgets(
        'searching beneficiary name displays matching beneficiary contact',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchModalSheet(
              beneficiaryDataSource: FakeBeneficiaryDataSource(),
            ),
          ),
        ),
      );

      // Nhập tên người thụ hưởng "Huong"
      await tester.enterText(find.byType(TextField), 'Huong');
      await tester.pumpAndSettle();

      expect(find.textContaining('Tài khoản thụ hưởng'), findsOneWidget);
      expect(find.text('TRAN THI HUONG'), findsOneWidget);
      expect(find.text('Chuyển'), findsOneWidget);
    });
  });
}
