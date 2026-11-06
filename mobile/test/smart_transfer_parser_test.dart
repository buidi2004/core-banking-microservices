import 'package:flutter_test/flutter_test.dart';
import 'package:sen_hong_bank/core/utils/smart_transfer_parser.dart';

void main() {
  group('SmartTransferParser', () {
    test('parses plain phone number', () {
      final res = SmartTransferParser.parse('0987654321');
      expect(res.hasTransferInfo, isTrue);
      expect(res.accountNumber, '0987654321');
    });

    test('parses transfer text with STK, Bank, Amount, Note', () {
      const text = 'STK: 19036789123456 - Techcombank - 500k - Noi dung: Tra tien an trua';
      final res = SmartTransferParser.parse(text);
      expect(res.hasTransferInfo, isTrue);
      expect(res.accountNumber, '19036789123456');
      expect(res.bankName, 'Techcombank');
      expect(res.amount, 500000);
      expect(res.note, 'Tra tien an trua');
    });

    test('parses natural language transfer message', () {
      const text = 'Chuyển tiền tới 0912345678 MB Bank số tiền 1.5tr ND cafe sang';
      final res = SmartTransferParser.parse(text);
      expect(res.hasTransferInfo, isTrue);
      expect(res.accountNumber, '0912345678');
      expect(res.bankName, 'MB Bank');
      expect(res.amount, 1500000);
      expect(res.note, 'cafe sang');
    });

    test('parses VietQR EMVCo format', () {
      // Chuỗi mẫu VietQR chuẩn EMVCo: Tag 38 length 45 (sub 00 len 10 + sub 01 len 27)
      const emv = '00020101021238450010A000000727012700069704220113098765432100053037045405500005802VN62160812Tien an trua6304ABCD';
      final res = SmartTransferParser.parse(emv);
      expect(res.hasTransferInfo, isTrue);
      expect(res.accountNumber, contains('0987654321'));
      expect(res.amount, 50000);
      expect(res.note, 'Tien an trua');
    });

    test('returns false for unrelated query', () {
      final res = SmartTransferParser.parse('tra cứu tiền điện evn');
      expect(res.hasTransferInfo, isFalse);
    });
  });
}
