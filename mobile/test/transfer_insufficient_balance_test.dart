import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/presentation/screens/transfer/transfer_result_screen.dart';

void main() {
  group('Transfer Insufficient Balance & Status UI Tests', () {
    testWidgets('TransferResultScreen displays Failure UI when status is FAILED', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransferResultScreen(
            recipient: 'NGUYEN VAN B',
            phoneNumber: '0987654321',
            amount: 500000,
            note: 'Chuyen tien loi so du',
            status: 'FAILED',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Phải hiển thị Giao Dịch Thất Bại
      expect(find.text('Giao Dịch Thất Bại'), findsOneWidget);
      expect(find.text('Giao Dịch Thành Công'), findsNothing);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
      expect(find.text('GIAO DỊCH BỊ TỪ CHỐI BỞI HỆ THỐNG'), findsOneWidget);
    });

    testWidgets('TransferResultScreen displays Success UI when status is SUCCESS', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransferResultScreen(
            recipient: 'NGUYEN VAN B',
            phoneNumber: '0987654321',
            amount: 500000,
            note: 'Chuyen tien thanh cong',
            status: 'SUCCESS',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Phải hiển thị Giao Dịch Thành Công
      expect(find.text('Giao Dịch Thành Công'), findsOneWidget);
      expect(find.text('Giao Dịch Thất Bại'), findsNothing);
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
      expect(find.text('CHỨNG TỪ ĐIỆN TỬ - SMART OTP XÁC THỰC'), findsOneWidget);
    });

    test('Amount string parsing with thousands separators (dots) parses correctly', () {
      double parseAmount(String text) {
        final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
        return double.tryParse(clean) ?? 0.0;
      }

      expect(parseAmount('100.000'), equals(100000.0));
      expect(parseAmount('50,000'), equals(50000.0));
      expect(parseAmount('1.000.000'), equals(1000000.0));
      expect(parseAmount('0'), equals(0.0));
      expect(parseAmount(''), equals(0.0));
    });

    test('Insufficient balance logic checks correctly for zero and positive balances', () {
      bool isExceeded(double amount, double balance, bool isLoading) {
        return !isLoading && amount > balance;
      }

      // Số dư = 0đ, chuyển 50.000đ -> Vượt số dư
      expect(isExceeded(50000, 0, false), isTrue);

      // Số dư = 10.000đ, chuyển 50.000đ -> Vượt số dư
      expect(isExceeded(50000, 10000, false), isTrue);

      // Số dư = 100.000đ, chuyển 50.000đ -> Đủ số dư
      expect(isExceeded(50000, 100000, false), isFalse);

      // Đang tải số dư -> Chưa vượt (chờ tải xong)
      expect(isExceeded(50000, 0, true), isFalse);
    });
  });
}
