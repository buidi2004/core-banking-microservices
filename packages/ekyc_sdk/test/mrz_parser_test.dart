// packages/ekyc_sdk/test/mrz_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ekyc_sdk/src/ocr/mrz_parser.dart';

void main() {
  group('MrzParser Tests', () {
    test('Check Digit Modulo 10 Calculation with [7, 3, 1] weights', () {
      // Ví dụ: Số CCCD 9 số cuối "099000123"
      // (0*7 + 9*3 + 9*1 + 0*7 + 0*3 + 0*1 + 1*7 + 2*3 + 3*1) = 0 + 27 + 9 + 0 + 0 + 0 + 7 + 6 + 3 = 52
      // 52 % 10 = 2
      final check = MrzParser.calculateCheckDigit('099000123');
      expect(check, 2);
    });

    test('Parse TD1 lines and auto-correct glare characters (O -> 0, I -> 1)', () {
      // Giả lập 3 dòng MRZ bị camera đọc nhầm do lóa sáng:
      // 'O' thay vì '0', 'I' thay vì '1'
      final rawLines = [
        'I<VNMO99OOO1232<<<<<<<<<<<<<', // Bị lóa: 'O' thay vì '0', check digit = 2
        '99O1O18M3OO1O19VNM<<<<<<<<<<<0', // Ngày sinh check=8, ngày hết hạn check=9
        'NGUYEN<<VAN<A<<<<<<<<<<<<<<<<<<',
      ];

      final result = MrzParser.parseTd1Lines(rawLines);
      expect(result, isNotNull);
      expect(result!.documentNumber, '099000123'); // Đã tự sửa về '0'
      expect(result.birthDateYYMMDD, '990101');
      expect(result.expiryDateYYMMDD, '300101');
      expect(result.fullName, 'NGUYEN VAN A');
      expect(result.isValidChecksum, isTrue);
      expect(result.wasAutoCorrected, isTrue);
    });

    test('Normalize noisy OCR symbols into < and handle surrounding lines', () {
      final noisyLines = [
        'CUC CANH SAT QUAN LY HANH CHINH VE TRAT TU XA HOI',
        'NGAY CAP: 15/05/2021',
        'I(VNMO99OOO1232<<<<<<<<<<<<<',
        '99O1O18M3OO1O19VNM<<<<-<<___0',
        'NGUYEN((VAN(A<<<<<<<<<<<<<<<<<<',
      ];

      final result = MrzParser.parseTd1Lines(
        noisyLines,
        knownCccd12: '079099000123',
        knownDob: '990101',
        knownExpiry: '300101',
      );

      expect(result, isNotNull);
      expect(result!.documentNumber, '099000123');
      expect(result.birthDateYYMMDD, '990101');
      expect(result.expiryDateYYMMDD, '300101');
      expect(result.fullName, 'NGUYEN VAN A');
      expect(result.isValidChecksum, isTrue);
      expect(result.fullCccdNumber, '079099000123');
    });

    test('FrontCccdResult hasBacKeys validation', () {
      const valid = FrontCccdResult(
        cccdNumber: '079099000123',
        documentNumber: '099000123',
        birthDateYYMMDD: '990101',
        expiryDateYYMMDD: '390101',
        fullName: 'NGUYEN VAN A',
      );
      expect(valid.hasBacKeys, isTrue);

      const invalid = FrontCccdResult(
        cccdNumber: '079099000123',
        documentNumber: '099000123',
        birthDateYYMMDD: null,
        expiryDateYYMMDD: '390101',
      );
      expect(invalid.hasBacKeys, isFalse);
    });

    test('extract12DigitCccdFromText extracts properly with or without prefix', () {
      expect(
        MrzScanner.extract12DigitCccdFromText('Số / No.: 079099000123'),
        '079099000123',
      );
      expect(
        MrzScanner.extract12DigitCccdFromText('Số / No.: 079 099 000 123'),
        '079099000123',
      );
      expect(
        MrzScanner.extract12DigitCccdFromText('Thẻ căn cước số 001099123456 cấp ngày...'),
        '001099123456',
      );
    });
  });
}
