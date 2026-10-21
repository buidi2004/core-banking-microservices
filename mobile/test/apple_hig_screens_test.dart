import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/screens/cards/payment_methods_screen.dart';
import 'package:sen_hong_bank/presentation/screens/more/more_screen.dart';
import 'package:sen_hong_bank/presentation/screens/profile_ekyc/user_profile_screen.dart';

class _TestMockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  _TestMockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('Apple HIG MoreScreen Widget Tests', () {
    testWidgets('MoreScreen renders search bar, quick actions grid and grouped sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Tiện Ích & Dịch Vụ'), findsOneWidget);

      // Verify Cupertino search field exists
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);

      // Verify Quick Actions Grid title & items
      expect(find.text('TIỆN ÍCH TRỌNG TÂM'), findsOneWidget);
      expect(find.text('Thẻ Sen Hồng'), findsWidgets);
      expect(find.text('Tiết Kiệm'), findsWidgets);
      expect(find.text('Vay Siêu Tốc'), findsWidgets);
      expect(find.text('Hóa Đơn'), findsWidgets);
      expect(find.text('Nạp ĐT (Top-up)'), findsWidgets);
      expect(find.text('Vé Vietlott'), findsWidgets);
      expect(find.text('Liên Kết NH'), findsWidgets);
      expect(find.text('Danh Bạ'), findsWidgets);

      // Verify Grouped Section Headers
      expect(find.text('TÀI CHÍNH & NGUỒN TIỀN'), findsOneWidget);
      expect(find.text('TIỆN ÍCH ĐỜI SỐNG'), findsOneWidget);
      expect(find.text('BẢO MẬT & HỆ THỐNG'), findsOneWidget);
      expect(find.text('HỖ TRỢ & PHÁP LÝ'), findsOneWidget);

      // Verify Logout and Footer
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
      expect(find.text('SEN HỒNG DIGITAL BANK'), findsOneWidget);
    });

    testWidgets('MoreScreen real-time search filters services dynamically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Search for 'tiết kiệm'
      final searchField = find.byType(CupertinoSearchTextField);
      await tester.enterText(searchField, 'tiết kiệm');
      await tester.pumpAndSettle();

      // Verify search results header
      expect(find.textContaining('KẾT QUẢ TÌM KIẾM'), findsOneWidget);
      expect(find.text('Tiết kiệm Sen Lộc Phát Online'), findsOneWidget);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Regular sections restored
      expect(find.text('TIỆN ÍCH TRỌNG TÂM'), findsOneWidget);
    });
  });

  group('Apple HIG UserProfileScreen Widget Tests', () {
    testWidgets('UserProfileScreen renders Apple ID header, metadata, contact info and consolidated VAT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dio = Dio()
        ..httpClientAdapter = _TestMockAdapter((options) {
          if (options.path.contains('/users/me')) {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {
                  'id': '88996688',
                  'fullName': 'Nguyễn Văn Sen',
                  'phoneNumber': '0988776655',
                  'email': 'sen.nguyen@senbank.vn',
                  'dob': '1992-05-18',
                  'createdAt': '2026-01-01T00:00:00Z',
                }
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          if (options.path.contains('/users/kyc/status')) {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {
                  'status': 'VERIFIED',
                  'level': 2,
                }
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString('{"success":true,"data":{}}', 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
        });

      final mockDs = ProfileRemoteDataSource(dio: dio);

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(profileDataSource: mockDs),
        ),
      );
      // Pump frames until async _loadProfile completes
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify title & action
      expect(find.text('Hồ Sơ Cá Nhân'), findsOneWidget);
      expect(find.text('Chỉnh sửa'), findsOneWidget);

      // Verify Profile Header Name & STK
      expect(find.text('NGUYỄN VĂN SEN'), findsOneWidget);
      expect(find.text('STK: 0988776655'), findsOneWidget);

      // Verify Metadata Card items
      expect(find.text('Mã định danh chủ ví (CID)'), findsOneWidget);
      expect(find.text('Chi nhánh quản lý'), findsOneWidget);
      expect(find.text('Trạng thái tài khoản'), findsOneWidget);

      // Verify Section Headers
      expect(find.text('THÔNG TIN LIÊN HỆ & ĐỊNH DANH'), findsOneWidget);
      expect(find.text('HÓA ĐƠN VAT & DOANH NGHIỆP'), findsOneWidget);
      expect(find.text('ĐỊNH DANH & HẠN MỨC GIAO DỊCH'), findsOneWidget);
      expect(find.text('QUYỀN RIÊNG TƯ & DỮ LIỆU CÁ NHÂN'), findsOneWidget);

      // Verify Contact Fields
      expect(find.text('Họ và tên (theo CCCD)'), findsOneWidget);
      expect(find.text('Số điện thoại đăng ký'), findsOneWidget);
      expect(find.text('Email nhận thông báo & Hóa đơn'), findsOneWidget);

      // Verify Consolidated VAT Invoicing
      expect(find.text('Hóa đơn điện tử VAT'), findsOneWidget);
      expect(find.text('Tự động gửi hóa đơn GTGT sau khi thanh toán phí'), findsOneWidget);

      // Verify Decree 13 Section
      expect(find.text('Quyền bảo vệ dữ liệu (Nghị định 13/2023)'), findsOneWidget);
    });
  });

  group('Apple HIG PaymentMethodsScreen Widget Tests', () {
    testWidgets('PaymentMethodsScreen renders Cupertino segmented control and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & segmented control
      expect(find.text('Nguồn Tiền & Phương Thức'), findsOneWidget);
      expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);

      // In Tab 0: Cards
      expect(find.text('THẺ THANH TOÁN QUỐC TẾ & GHI NỢ'), findsOneWidget);
      expect(find.text('Sen Hồng Visa Signature'), findsOneWidget);

      // Switch to Tab 1: Bank Accounts
      await tester.tap(find.text('Ngân Hàng Liên Kết'));
      await tester.pumpAndSettle();

      expect(find.text('TÀI KHOẢN NGÂN HÀNG LIÊN KẾT'), findsOneWidget);
    });
  });
}
