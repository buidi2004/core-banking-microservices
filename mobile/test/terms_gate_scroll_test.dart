import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/auth/terms_of_service_screen.dart';

void main() {
  testWidgets('TermsOfServiceScreen requires scrolling to bottom before accepting when isRegistrationGate is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TermsOfServiceScreen(isRegistrationGate: true),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra ban đầu: nút ở thanh đáy chưa mở khóa (yêu cầu cuộn xuống cuối)
    expect(find.textContaining('Cuộn xuống cuối để chấp nhận'), findsWidgets);
    expect(find.text('BƯỚC 1: XÁC NHẬN THỎA THUẬN NGÂN HÀNG SỐ'), findsOneWidget);

    // 2. Cuộn xuống đáy màn hình
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Chương VI: Trách Nhiệm Bảo Mật Của Khách Hàng'),
      500,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    // Tiếp tục kéo mạnh xuống đáy để đạt maxScrollExtent
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pumpAndSettle();

    // 3. Nút chấp nhận điều khoản đã mở khóa thành công!
    expect(find.text('Tôi Đã Đọc Và Chấp Nhận Điều Khoản'), findsOneWidget);
  });
}

