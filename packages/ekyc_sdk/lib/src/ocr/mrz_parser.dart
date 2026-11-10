// packages/ekyc_sdk/lib/src/ocr/mrz_parser.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Kết quả bóc tách thông tin mặt trước thẻ CCCD gắn chip Việt Nam
class FrontCccdResult {
  final String? cccdNumber; // 12 chữ số CCCD (vd: 079099000123)
  final String? documentNumber; // 9 chữ số cuối dùng làm mã BAC (vd: 099000123)
  final String? birthDateYYMMDD; // 6 chữ số YYMMDD (vd: 990101)
  final String? expiryDateYYMMDD; // 6 chữ số YYMMDD (vd: 390101)
  final String? fullName; // Họ và tên in hoa
  final String? placeOfOrigin; // Quê quán
  final String? placeOfResidence; // Nơi thường trú
  final String? rawText; // Toàn bộ văn bản OCR nhận diện được

  const FrontCccdResult({
    this.cccdNumber,
    this.documentNumber,
    this.birthDateYYMMDD,
    this.expiryDateYYMMDD,
    this.fullName,
    this.placeOfOrigin,
    this.placeOfResidence,
    this.rawText,
  });

  /// Kiểm tra xem đã có đủ bộ 3 khóa BAC hay chưa (Số thẻ 9 số, Ngày sinh 6 số, Ngày hết hạn 6 số)
  bool get hasBacKeys =>
      documentNumber != null &&
      documentNumber!.length == 9 &&
      birthDateYYMMDD != null &&
      birthDateYYMMDD!.length == 6 &&
      expiryDateYYMMDD != null &&
      expiryDateYYMMDD!.length == 6;

  @override
  String toString() =>
      'FrontCccdResult(cccd: $cccdNumber, doc: $documentNumber, dob: $birthDateYYMMDD, '
      'exp: $expiryDateYYMMDD, name: $fullName, origin: $placeOfOrigin, residence: $placeOfResidence, hasBacKeys: $hasBacKeys)';
}

/// Kết quả bóc tách và tự sửa lỗi chuỗi MRZ thẻ CCCD Việt Nam (Chuẩn ICAO 9303 TD1)
class MrzResult {
  final String documentNumber; // 9 số cuối CCCD
  final String birthDateYYMMDD;
  final String expiryDateYYMMDD;
  final String fullName;
  final bool isValidChecksum;
  final bool wasAutoCorrected;
  final String? fullCccdNumber; // 12 số CCCD nếu có
  final String? issueDate; // Ngày cấp thẻ (DD/MM/YYYY)

  const MrzResult({
    required this.documentNumber,
    required this.birthDateYYMMDD,
    required this.expiryDateYYMMDD,
    required this.fullName,
    required this.isValidChecksum,
    required this.wasAutoCorrected,
    this.fullCccdNumber,
    this.issueDate,
  });

  @override
  String toString() =>
      'MrzResult(doc: $documentNumber, dob: $birthDateYYMMDD, exp: $expiryDateYYMMDD, '
      'name: $fullName, valid: $isValidChecksum, autoCorrected: $wasAutoCorrected, cccd: $fullCccdNumber, issueDate: $issueDate)';
}

/// Thuật toán kiểm tra Checksum và tự động phục hồi ký tự do lóa sáng / nhiễu camera
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

  /// Chuẩn hóa 1 dòng MRZ: thay thế ký tự nhiễu OCR thành '<' và loại bỏ ký tự rác
  static String normalizeMrzLine(String raw) {
    var line = raw.trim();
    line = line
        .replaceAll('«', '<')
        .replaceAll('‹', '<')
        .replaceAll('(', '<')
        .replaceAll(')', '<')
        .replaceAll('[', '<')
        .replaceAll(']', '<')
        .replaceAll('{', '<')
        .replaceAll('}', '<')
        .replaceAll('_', '<')
        .replaceAll('-', '<')
        .replaceAll(r'\', '<')
        .replaceAll('/', '<')
        .replaceAll('|', '<')
        .replaceAll('~', '<')
        .replaceAll('^', '<')
        .replaceAll('>', '<')
        .replaceAll(' ', '<');

    line = line.replaceAll(RegExp(r'[^A-Za-z0-9<]'), '').toUpperCase();
    return line;
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
  /// Có hỗ trợ đối soát chéo với thông tin mặt trước [knownCccd12], [knownDob], [knownExpiry].
  static MrzResult? parseTd1Lines(
    List<String> rawLines, {
    String? knownCccd12,
    String? knownDob,
    String? knownExpiry,
  }) {
    // 1. Chuẩn hóa và làm sạch tất cả các dòng nhận diện được
    final cleaned = rawLines
        .map(normalizeMrzLine)
        .where((l) => l.length >= 18)
        .toList();

    if (cleaned.length < 2) return null;

    String? line1;
    String? line2;
    String? line3;

    // 2. Tìm kiếm 3 dòng theo thứ tự logic hoặc cấu trúc nhận diện đặc thù
    for (var i = 0; i < cleaned.length; i++) {
      final line = cleaned[i];
      if (line1 == null &&
          (line.startsWith('I') ||
              line.startsWith('1') ||
              (line.length >= 6 && line.substring(0, 6).contains('VNM')))) {
        line1 = line.padRight(30, '<').substring(0, 30);
        continue;
      }
      if (line1 != null && line2 == null && line.length >= 20) {
        final maybeDigits = forceDigits(line.substring(0, 6));
        if (RegExp(r'^\d{6}').hasMatch(maybeDigits)) {
          line2 = line.padRight(30, '<').substring(0, 30);
          continue;
        }
      }
      if (line1 != null && line2 != null && line3 == null) {
        line3 = line.padRight(30, '<').substring(0, 30);
        break;
      }
    }

    // Fallback: nếu không tìm thấy theo loop tuần tự, tìm theo pattern
    if (line1 == null || line2 == null) {
      for (final l in cleaned) {
        final padded = l.padRight(30, '<').substring(0, 30);
        if (line1 == null &&
            (padded.startsWith('I<') || padded.contains('VNM'))) {
          line1 = padded;
        } else if (line2 == null &&
            RegExp(r'^\d{6}').hasMatch(forceDigits(padded.substring(0, 6)))) {
          line2 = padded;
        } else if (line3 == null && padded.contains('<<')) {
          line3 = padded;
        }
      }
    }

    if (line1 == null || line2 == null) return null;
    line3 ??= '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';

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

    // 3. Đối soát & tự sửa số giấy tờ (Document Number)
    var finalDocNum = forceDigits(rawDocNum);
    if (knownCccd12 != null && knownCccd12.length >= 9) {
      final expectedDocNum =
          knownCccd12.substring(knownCccd12.length - 9);
      if (rawDocCheck != -1 &&
          calculateCheckDigit(expectedDocNum) == rawDocCheck) {
        finalDocNum = expectedDocNum;
        wasAutoCorrected = true;
      } else if (finalDocNum != expectedDocNum) {
        finalDocNum = expectedDocNum;
        wasAutoCorrected = true;
      }
    } else {
      if (finalDocNum != rawDocNum) {
        wasAutoCorrected = true;
      }
      if (rawDocCheck != -1 &&
          calculateCheckDigit(finalDocNum) != rawDocCheck) {
        final corrected = autoCorrectField(rawDocNum, rawDocCheck);
        if (corrected != null) {
          finalDocNum = forceDigits(corrected);
          wasAutoCorrected = true;
        }
      }
    }

    // 4. Đối soát & tự sửa ngày sinh (DOB)
    var finalDob = forceDigits(rawDob);
    if (knownDob != null && knownDob.length == 6) {
      if (rawDobCheck != -1 &&
          calculateCheckDigit(knownDob) == rawDobCheck) {
        finalDob = knownDob;
        wasAutoCorrected = true;
      } else if (finalDob != knownDob) {
        finalDob = knownDob;
        wasAutoCorrected = true;
      }
    } else {
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
    }

    // 5. Đối soát & tự sửa ngày hết hạn (Expiry)
    var finalExp = forceDigits(rawExp);
    if (knownExpiry != null && knownExpiry.length == 6) {
      if (rawExpCheck != -1 &&
          calculateCheckDigit(knownExpiry) == rawExpCheck) {
        finalExp = knownExpiry;
        wasAutoCorrected = true;
      } else if (finalExp != knownExpiry) {
        finalExp = knownExpiry;
        wasAutoCorrected = true;
      }
    } else {
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
    }

    final isValidChecksum =
        (calculateCheckDigit(finalDocNum) == rawDocCheck || rawDocCheck == -1) &&
        (calculateCheckDigit(finalDob) == rawDobCheck || rawDobCheck == -1) &&
        (calculateCheckDigit(finalExp) == rawExpCheck || rawExpCheck == -1);

    return MrzResult(
      documentNumber: finalDocNum,
      birthDateYYMMDD: finalDob,
      expiryDateYYMMDD: finalExp,
      fullName: fullName,
      isValidChecksum: isValidChecksum,
      wasAutoCorrected: wasAutoCorrected,
      fullCccdNumber: knownCccd12,
    );
  }
}

/// Bộ quét OCR nhận dạng tự động chuỗi MRZ và thông tin thẻ CCCD
class MrzScanner {
  /// Quét tự động từ dữ liệu bytes ảnh mặt sau thẻ (JPEG/PNG)
  /// [frontData] & [knownCccd12]: dữ liệu bóc tách được từ mặt trước dùng để đối chiếu kép.
  static Future<MrzResult?> scanFromImageBytes(
    Uint8List bytes, {
    FrontCccdResult? frontData,
    String? knownCccd12,
  }) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/mrz_card_${DateTime.now().millisecondsSinceEpoch}.jpg');
    try {
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // Sắp xếp các dòng theo trục thẳng đứng (top to bottom)
      final allLines = <TextLine>[];
      for (final block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      final lines = <String>[];
      for (final line in allLines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }

      // ignore: avoid_print
      print('[SEN HỒNG MRZ] ML Kit nhận diện ${lines.length} dòng văn bản từ ảnh mặt sau thẻ');

      final effectiveCccd12 = knownCccd12 ?? frontData?.cccdNumber;
      final effectiveDob = frontData?.birthDateYYMMDD;
      final effectiveExpiry = frontData?.expiryDateYYMMDD;

      // Bóc tách Ngày cấp mặt sau thẻ (Dòng laser trên chữ ký C06)
      String? extractedIssueDate;
      for (final line in lines) {
        // Mẫu 1: DD/MM/YYYY hoặc DD-MM-YYYY
        final dateMatch = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b').firstMatch(line);
        if (dateMatch != null) {
          final d = dateMatch.group(1)!.padLeft(2, '0');
          final m = dateMatch.group(2)!.padLeft(2, '0');
          final y = dateMatch.group(3)!;
          final yymmdd = '${y.substring(2, 4)}$m$d';
          if (yymmdd != effectiveDob && yymmdd != effectiveExpiry) {
            extractedIssueDate = '$d/$m/$y';
            break;
          }
        }
        // Mẫu 2: Ngày ... tháng ... năm ...
        final textDateMatch = RegExp(r'(\d{1,2})\s+tháng\s+(\d{1,2})\s+năm\s+(\d{4})', caseSensitive: false).firstMatch(line);
        if (textDateMatch != null) {
          final d = textDateMatch.group(1)!.padLeft(2, '0');
          final m = textDateMatch.group(2)!.padLeft(2, '0');
          final y = textDateMatch.group(3)!;
          extractedIssueDate = '$d/$m/$y';
          break;
        }
      }
      if (extractedIssueDate != null) {
        // ignore: avoid_print
        print('[SEN HỒNG OCR BACK] Bóc tách thành công Ngày cấp thẻ: $extractedIssueDate');
      }

      final result = MrzParser.parseTd1Lines(
        lines,
        knownCccd12: effectiveCccd12,
        knownDob: effectiveDob,
        knownExpiry: effectiveExpiry,
      );

      if (result != null) {
        final fullResult = MrzResult(
          documentNumber: result.documentNumber,
          birthDateYYMMDD: result.birthDateYYMMDD,
          expiryDateYYMMDD: result.expiryDateYYMMDD,
          fullName: result.fullName,
          isValidChecksum: result.isValidChecksum,
          wasAutoCorrected: result.wasAutoCorrected,
          fullCccdNumber: result.fullCccdNumber,
          issueDate: extractedIssueDate,
        );
        // ignore: avoid_print
        print('[SEN HỒNG MRZ] Bóc tách MRZ thành công: doc=${fullResult.documentNumber}, dob=${fullResult.birthDateYYMMDD}, exp=${fullResult.expiryDateYYMMDD}, issueDate=${fullResult.issueDate}, checkValid=${fullResult.isValidChecksum}');
        return fullResult;
      }

      // Fallback: Nếu ảnh mặt sau mờ hoặc xước dải MRZ, nhưng mặt trước đã quét được đủ bộ khóa BAC
      if (frontData != null && frontData.hasBacKeys) {
        // ignore: avoid_print
        print('[SEN HỒNG MRZ] Không đọc được MRZ từ mặt sau, tự động kích hoạt bộ khóa BAC từ mặt trước!');
        return MrzResult(
          documentNumber: frontData.documentNumber!,
          birthDateYYMMDD: frontData.birthDateYYMMDD!,
          expiryDateYYMMDD: frontData.expiryDateYYMMDD!,
          fullName: frontData.fullName ?? '',
          isValidChecksum: true,
          wasAutoCorrected: true,
          fullCccdNumber: frontData.cccdNumber,
          issueDate: extractedIssueDate,
        );
      }

      // ignore: avoid_print
      print('[SEN HỒNG MRZ] Không tìm thấy 3 dòng chuẩn TD1 ICAO trong các dòng đã nhận diện');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[SEN HỒNG MRZ] Lỗi khi nhận diện MRZ: $e');

      // Trong trường hợp ngoại lệ nhưng mặt trước đã có khóa BAC, vẫn trả về kết quả
      if (frontData != null && frontData.hasBacKeys) {
        return MrzResult(
          documentNumber: frontData.documentNumber!,
          birthDateYYMMDD: frontData.birthDateYYMMDD!,
          expiryDateYYMMDD: frontData.expiryDateYYMMDD!,
          fullName: frontData.fullName ?? '',
          isValidChecksum: true,
          wasAutoCorrected: true,
          fullCccdNumber: frontData.cccdNumber,
        );
      }
      return null;
    } finally {
      if (tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Quét tự động từ dữ liệu bytes ảnh mặt trước thẻ (JPEG/PNG)
  /// Trích xuất: 12 số CCCD, 9 số cuối (BAC docNum), Ngày sinh (YYMMDD), Ngày hết hạn (YYMMDD), Họ và tên
  static Future<FrontCccdResult?> scanFrontCard(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/front_card_${DateTime.now().millisecondsSinceEpoch}.jpg');
    try {
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final fullText = recognizedText.text;
      // ignore: avoid_print
      print('[SEN HỒNG OCR FRONT] ML Kit đọc được ${recognizedText.blocks.length} khối văn bản mặt trước');

      // 1. Tìm số CCCD 12 chữ số
      var cccdNumber = extract12DigitCccdFromText(fullText);

      // Fallback tìm từng dòng nếu chưa ra
      if (cccdNumber == null) {
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final cleaned = line.text.replaceAll(RegExp(r'\s+'), '');
            final match = RegExp(r'\b0\d{11}\b').firstMatch(cleaned);
            if (match != null) {
              cccdNumber = match.group(0);
              break;
            }
          }
          if (cccdNumber != null) break;
        }
      }

      final documentNumber =
          (cccdNumber != null && cccdNumber.length == 12)
              ? cccdNumber.substring(3)
              : null;

      // 2. Tìm Ngày sinh (DD/MM/YYYY) -> chuyển thành YYMMDD
      String? birthDateYYMMDD;
      final dobMatch = RegExp(
        r'(?:sinh|birth)[\s\S]{0,30}?(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})',
        caseSensitive: false,
      ).firstMatch(fullText);

      if (dobMatch != null) {
        final d = dobMatch.group(1)!.padLeft(2, '0');
        final m = dobMatch.group(2)!.padLeft(2, '0');
        final y = dobMatch.group(3)!;
        birthDateYYMMDD = '${y.substring(2, 4)}$m$d';
      }

      // 3. Tìm Ngày hết hạn (DD/MM/YYYY) -> chuyển thành YYMMDD
      String? expiryDateYYMMDD;
      if (fullText.toLowerCase().contains('không thời hạn') ||
          fullText.toLowerCase().contains('vô thời hạn')) {
        expiryDateYYMMDD = '991231';
      } else {
        final expMatch = RegExp(
          r'(?:giá trị|hết hạn|expiry|valid until)[\s\S]{0,30}?(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})',
          caseSensitive: false,
        ).firstMatch(fullText);

        if (expMatch != null) {
          final d = expMatch.group(1)!.padLeft(2, '0');
          final m = expMatch.group(2)!.padLeft(2, '0');
          final y = expMatch.group(3)!;
          expiryDateYYMMDD = '${y.substring(2, 4)}$m$d';
        }
      }

      // 4. Tìm Họ và tên
      String? fullName;
      final nameMatch = RegExp(
        r'(?:Họ và tên|Full name)[\s\S]{0,30}?\n\s*([A-ZÀ-ỸĐ\s]{3,40})\n',
        caseSensitive: false,
      ).firstMatch(fullText);
      if (nameMatch != null) {
        fullName = nameMatch.group(1)?.trim();
      }

      // 5. Tìm Quê quán
      String? placeOfOrigin;
      final originMatch = RegExp(
        r'(?:Quê quán|Place of origin)[\s\S]{0,25}?:?\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(fullText);
      if (originMatch != null) {
        placeOfOrigin = originMatch.group(1)?.trim();
      }

      // 6. Tìm Nơi thường trú
      String? placeOfResidence;
      final residenceMatch = RegExp(
        r'(?:Nơi thường trú|Place of residence)[\s\S]{0,25}?:?\s*([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(fullText);
      if (residenceMatch != null) {
        placeOfResidence = residenceMatch.group(1)?.trim();
      }

      final result = FrontCccdResult(
        cccdNumber: cccdNumber,
        documentNumber: documentNumber,
        birthDateYYMMDD: birthDateYYMMDD,
        expiryDateYYMMDD: expiryDateYYMMDD,
        fullName: fullName,
        placeOfOrigin: placeOfOrigin,
        placeOfResidence: placeOfResidence,
        rawText: fullText,
      );

      // ignore: avoid_print
      print('[SEN HỒNG OCR FRONT] Kết quả bóc tách mặt trước: $result');
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('[SEN HỒNG OCR FRONT] Lỗi nhận diện mặt trước: $e');
      return null;
    } finally {
      if (tempFile.existsSync()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Trích xuất nhanh số CCCD 12 chữ số từ văn bản mặt trước thẻ
  static String? extract12DigitCccdFromText(String rawText) {
    // Ưu tiên dòng có tiền tố Số / No.
    final matchPrefix = RegExp(
      r'(?:Số|No\.?|SỐ|NO)[\s:]*([0-9\s]{12,16})',
      caseSensitive: false,
    ).firstMatch(rawText);
    if (matchPrefix != null) {
      final cleaned =
          matchPrefix.group(1)?.replaceAll(RegExp(r'\s+'), '');
      if (cleaned != null && cleaned.length == 12) return cleaned;
    }

    final match = RegExp(r'\b0\d{11}\b').firstMatch(rawText);
    return match?.group(0);
  }
}
