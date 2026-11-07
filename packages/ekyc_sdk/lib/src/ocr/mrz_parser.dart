// packages/ekyc_sdk/lib/src/ocr/mrz_parser.dart

/// Kết quả bóc tách và tự sửa lỗi chuỗi MRZ thẻ CCCD Việt Nam (Chuẩn ICAO 9303 TD1)
class MrzResult {
  final String documentNumber; // 9 số cuối CCCD
  final String birthDateYYMMDD;
  final String expiryDateYYMMDD;
  final String fullName;
  final bool isValidChecksum;
  final bool wasAutoCorrected;

  const MrzResult({
    required this.documentNumber,
    required this.birthDateYYMMDD,
    required this.expiryDateYYMMDD,
    required this.fullName,
    required this.isValidChecksum,
    required this.wasAutoCorrected,
  });

  @override
  String toString() =>
      'MrzResult(doc: $documentNumber, dob: $birthDateYYMMDD, exp: $expiryDateYYMMDD, '
      'name: $fullName, valid: $isValidChecksum, autoCorrected: $wasAutoCorrected)';
}

/// Thuật toán kiểm tra Checksum và tự động phục hồi ký tự do lóa sáng
class MrzParser {
  // Trọng số ICAO 9303 tuần hoàn: 7, 3, 1
  static const List<int> _weights = [7, 3, 1];

  /// Tính Check Digit mod 10 theo chuẩn ICAO 9303
  static int calculateCheckDigit(String input) {
    var sum = 0;
    for (var i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      int value;

      if (code >= 48 && code <= 57) {
        // '0' - '9'
        value = code - 48;
      } else if (code >= 65 && code <= 90) {
        // 'A' - 'Z'
        value = code - 55;
      } else if (code >= 97 && code <= 122) {
        // 'a' - 'z'
        value = code - 87;
      } else {
        // '<' hoặc ký tự khác
        value = 0;
      }

      sum += value * _weights[i % 3];
    }
    return sum % 10;
  }

  /// Bảng ánh xạ các ký tự thường bị OCR đọc nhầm do lóa sáng hoặc bóng đèn trần
  static const Map<String, List<String>> _glareMap = {
    '0': ['O', 'D', 'Q', 'U'],
    'O': ['0', 'Q', 'D'],
    '1': ['I', 'l', '|', 'T'],
    'I': ['1', 'l', '|'],
    '2': ['Z'],
    'Z': ['2'],
    '5': ['S', 's'],
    'S': ['5'],
    '8': ['B'],
    'B': ['8'],
  };

  /// Tự động sửa lỗi chuỗi số bị lóa sáng bằng cách đối chiếu Check Digit
  static String? autoCorrectField(String rawField, int expectedCheckDigit) {
    if (calculateCheckDigit(rawField) == expectedCheckDigit) {
      return rawField;
    }

    // Thử thay thế từng ký tự nghi vấn
    final chars = rawField.split('');
    for (var i = 0; i < chars.length; i++) {
      final currentChar = chars[i];
      final candidates = _glareMap[currentChar] ?? [];

      for (final candidate in candidates) {
        final testChars = List<String>.from(chars);
        testChars[i] = candidate;
        final candidateStr = testChars.join('');
        if (calculateCheckDigit(candidateStr) == expectedCheckDigit) {
          return candidateStr;
        }
      }
    }

    // Thử thay thế 2 ký tự lóa sáng đồng thời
    for (var i = 0; i < chars.length; i++) {
      for (var j = i + 1; j < chars.length; j++) {
        final candsI = _glareMap[chars[i]] ?? [];
        final candsJ = _glareMap[chars[j]] ?? [];

        for (final candI in candsI) {
          for (final candJ in candsJ) {
            final testChars = List<String>.from(chars);
            testChars[i] = candI;
            testChars[j] = candJ;
            final candidateStr = testChars.join('');
            if (calculateCheckDigit(candidateStr) == expectedCheckDigit) {
              return candidateStr;
            }
          }
        }
      }
    }

    return null; // Không thể tự sửa
  }

  /// Chuẩn hóa và làm sạch chuỗi số (Ép các ký tự chữ cái lóa sáng về số)
  static String forceDigits(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('Q', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('B', '8');
  }

  /// Phân tích 3 dòng MRZ của thẻ CCCD gắn chip Việt Nam (TD1 - 3 dòng x 30 ký tự)
  static MrzResult? parseTd1Lines(List<String> rawLines) {
    // 1. Lọc và làm sạch các dòng ký tự
    final cleaned = rawLines
        .map((l) => l.replaceAll(RegExp(r'[^A-Za-z0-9<]'), '').toUpperCase())
        .where((l) => l.length >= 26)
        .toList();

    if (cleaned.length < 3) return null;

    // Tìm 3 dòng TD1 liên tiếp
    String? line1;
    String? line2;
    String? line3;

    for (var i = 0; i <= cleaned.length - 3; i++) {
      if (cleaned[i].startsWith('I') || cleaned[i].contains('VNM')) {
        line1 = cleaned[i].padRight(30, '<').substring(0, 30);
        line2 = cleaned[i + 1].padRight(30, '<').substring(0, 30);
        line3 = cleaned[i + 2].padRight(30, '<').substring(0, 30);
        break;
      }
    }

    if (line1 == null || line2 == null || line3 == null) return null;

    var wasAutoCorrected = false;

    // Dòng 1: I<VNM0790990001239<<<<<<<<<<<<<
    // Vị trí 5..14 (9 ký tự): Số giấy tờ (9 số cuối của CCCD 12 số)
    var rawDocNum = line1.substring(5, 14);
    final rawDocCheck = int.tryParse(line1.substring(14, 15)) ?? -1;

    // Dòng 2: 9901015M3001018VNM<<<<<<<<<<<0
    // Vị trí 0..6: Ngày sinh YYMMDD
    var rawDob = line2.substring(0, 6);
    final rawDobCheck = int.tryParse(line2.substring(6, 7)) ?? -1;

    // Vị trí 8..14: Ngày hết hạn YYMMDD
    var rawExp = line2.substring(8, 14);
    final rawExpCheck = int.tryParse(line2.substring(14, 15)) ?? -1;

    // Dòng 3: NGUYEN<<VAN<A<<<<<<<<<<<<<<<<<<
    final fullName =
        line3.replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2. Kiểm tra và tự sửa lỗi lóa sáng cho số giấy tờ
    var finalDocNum = forceDigits(rawDocNum);
    if (finalDocNum != rawDocNum) {
      wasAutoCorrected = true;
    }
    if (rawDocCheck != -1 && calculateCheckDigit(finalDocNum) != rawDocCheck) {
      final corrected = autoCorrectField(rawDocNum, rawDocCheck);
      if (corrected != null) {
        finalDocNum = forceDigits(corrected);
        wasAutoCorrected = true;
      }
    }

    // 3. Kiểm tra và tự sửa lỗi lóa sáng cho ngày sinh
    var finalDob = forceDigits(rawDob);
    if (finalDob != rawDob) {
      wasAutoCorrected = true;
    }
    if (rawDobCheck != -1 && calculateCheckDigit(finalDob) != rawDobCheck) {
      final corrected = autoCorrectField(rawDob, rawDobCheck);
      if (corrected != null) {
        finalDob = forceDigits(corrected);
        wasAutoCorrected = true;
      }
    }

    // 4. Kiểm tra và tự sửa lỗi lóa sáng cho ngày hết hạn
    var finalExp = forceDigits(rawExp);
    if (finalExp != rawExp) {
      wasAutoCorrected = true;
    }
    if (rawExpCheck != -1 && calculateCheckDigit(finalExp) != rawExpCheck) {
      final corrected = autoCorrectField(rawExp, rawExpCheck);
      if (corrected != null) {
        finalExp = forceDigits(corrected);
        wasAutoCorrected = true;
      }
    }

    final isValidChecksum = (calculateCheckDigit(finalDocNum) == rawDocCheck) &&
        (calculateCheckDigit(finalDob) == rawDobCheck) &&
        (calculateCheckDigit(finalExp) == rawExpCheck);

    return MrzResult(
      documentNumber: finalDocNum,
      birthDateYYMMDD: finalDob,
      expiryDateYYMMDD: finalExp,
      fullName: fullName,
      isValidChecksum: isValidChecksum,
      wasAutoCorrected: wasAutoCorrected,
    );
  }
}
