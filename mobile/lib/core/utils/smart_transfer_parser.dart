/// Bộ phân tích thông minh thông tin chuyển tiền từ Văn bản & Mã QR (SenAI)
class ParsedTransferData {
  final String? accountNumber;
  final String? bankName;
  final String? bankBin;
  final String? recipientName;
  final double? amount;
  final String? note;
  final String rawText;
  final bool hasTransferInfo;

  const ParsedTransferData({
    this.accountNumber,
    this.bankName,
    this.bankBin,
    this.recipientName,
    this.amount,
    this.note,
    required this.rawText,
    required this.hasTransferInfo,
  });

  /// Tạo URI chuyển tiền tự động
  Uri buildTransferUri() {
    final cleanAccount = (accountNumber ?? '').replaceAll(RegExp(r'\s+'), '');
    final name = (recipientName != null && recipientName!.isNotEmpty)
        ? recipientName!
        : (cleanAccount.isNotEmpty ? cleanAccount : 'Người nhận');

    if (amount != null && amount! > 0) {
      return Uri(
        path: '/transfer/confirm',
        queryParameters: {
          'recipient': name,
          'phoneNumber': cleanAccount,
          'amount': amount!.toInt().toString(),
          if (note != null && note!.isNotEmpty) 'note': note!,
        },
      );
    } else {
      return Uri(
        path: '/transfer/amount',
        queryParameters: {
          'recipient': name,
          'phoneNumber': cleanAccount,
          if (note != null && note!.isNotEmpty) 'note': note!,
        },
      );
    }
  }
}

class SmartTransferParser {
  // Danh bạ định danh ngân hàng phổ biến tại Việt Nam
  static final Map<String, (String name, String bin)> _banks = {
    'vietcombank': ('Vietcombank', '970436'),
    'vcb': ('Vietcombank', '970436'),
    'mbbank': ('MB Bank', '970422'),
    'mb bank': ('MB Bank', '970422'),
    'mb': ('MB Bank', '970422'),
    'techcombank': ('Techcombank', '970407'),
    'tcb': ('Techcombank', '970407'),
    'bidv': ('BIDV', '970418'),
    'vietinbank': ('VietinBank', '970415'),
    'ctg': ('VietinBank', '970415'),
    'acb': ('ACB', '970416'),
    'vpbank': ('VPBank', '970432'),
    'vpb': ('VPBank', '970432'),
    'tpbank': ('TPBank', '970423'),
    'tpb': ('TPBank', '970423'),
    'sacombank': ('Sacombank', '970403'),
    'stb': ('Sacombank', '970403'),
    'hdbank': ('HDBank', '970437'),
    'hdb': ('HDBank', '970437'),
    'vib': ('VIB', '970441'),
    'shb': ('SHB', '970443'),
    'msb': ('MSB', '970426'),
    'ocb': ('OCB', '970448'),
    'agribank': ('Agribank', '970405'),
    'senbank': ('Ví Sen Hồng', '970499'),
    'sen hong': ('Ví Sen Hồng', '970499'),
    'senhong': ('Ví Sen Hồng', '970499'),
  };

  /// Phân tích dữ liệu văn bản từ clipboard hoặc OCR/QR code
  static ParsedTransferData parse(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return ParsedTransferData(rawText: text, hasTransferInfo: false);
    }

    // 1. Kiểm tra nếu là chuỗi mã VietQR EMVCo chuẩn (bắt đầu bằng 000201)
    if (text.startsWith('000201')) {
      final emvData = _parseEmvCo(text);
      if (emvData != null) {
        return emvData;
      }
    }

    // 2. Phân tích nội dung văn bản tự nhiên (Natural Language Transfer Parser)
    String? matchedAccount;
    String? matchedBankName;
    String? matchedBankBin;
    String? matchedRecipientName;
    double? matchedAmount;
    String? matchedNote;

    final lower = text.toLowerCase();

    // 2.1 Tìm kiếm tên Ngân hàng
    for (final entry in _banks.entries) {
      final key = entry.key;
      // Dùng regex boundary để tránh nhầm từ con
      final reg = RegExp('\\b${RegExp.escape(key)}\\b', caseSensitive: false);
      if (reg.hasMatch(lower)) {
        matchedBankName = entry.value.$1;
        matchedBankBin = entry.value.$2;
        break;
      }
    }

    // 2.2 Tìm số tài khoản (STK / SĐT)
    // Ưu tiên cú pháp có tiền tố rõ ràng: STK, số tk, tài khoản, account, sdt
    final stkExplicitReg = RegExp(
      r'(?:stk|số\s*tk|so\s*tk|số\s*tài\s*khoản|so\s*tai\s*khoan|tài\s*khoản|tai\s*khoan|tk|acc|stk\s*[:\-])\s*[:\-]?\s*([0-9]{6,19})',
      caseSensitive: false,
    );
    final stkMatch = stkExplicitReg.firstMatch(text);
    if (stkMatch != null) {
      matchedAccount = stkMatch.group(1);
    }

    // Nếu chưa thấy, tìm số điện thoại 10 số (bắt đầu 03, 05, 07, 08, 09)
    if (matchedAccount == null) {
      final phoneReg = RegExp(r'\b(0[35789][0-9]{8})\b');
      final phoneMatch = phoneReg.firstMatch(text);
      if (phoneMatch != null) {
        matchedAccount = phoneMatch.group(1);
      }
    }

    // Nếu chưa thấy, tìm chuỗi số dài liên tiếp từ 8 đến 16 số (STK thông dụng)
    if (matchedAccount == null) {
      final digitsReg = RegExp(r'\b([0-9]{8,16})\b');
      final digitsMatch = digitsReg.firstMatch(text);
      if (digitsMatch != null) {
        matchedAccount = digitsMatch.group(1);
      }
    }

    // 2.3 Tìm số tiền chuyển
    // Cú pháp tiền tố: số tiền, tiền, ck, amount, st, vnd
    final amountExplicitReg = RegExp(
      r'(?:số\s*tiền|so\s*tien|tiền|tien|ck|chuyển|chuyen|amount|st)\s*[:\-]?\s*([0-9\.,]+)\s*(k|vnd|đ|d|triệu|trieu|tr|nghìn|nghin)?',
      caseSensitive: false,
    );
    final amtMatch = amountExplicitReg.firstMatch(text);
    if (amtMatch != null) {
      final numStr = amtMatch.group(1)!;
      final unit = amtMatch.group(2)?.toLowerCase();
      matchedAmount = _parseAmountValue(numStr, unit);
    }

    // Nếu chưa thấy số tiền, tìm số đi liền với đơn vị tiền tệ (ví dụ: 50k, 200k, 1.5tr, 500.000d, 1000000 vnd)
    if (matchedAmount == null) {
      final unitAmtReg = RegExp(
        r'\b([0-9]+(?:[\.,][0-9]+)?)\s*(k|vnd|đ|d|triệu|trieu|tr|nghìn|nghin)\b',
        caseSensitive: false,
      );
      final unitMatch = unitAmtReg.firstMatch(text);
      if (unitMatch != null) {
        final numStr = unitMatch.group(1)!;
        final unit = unitMatch.group(2)!.toLowerCase();
        matchedAmount = _parseAmountValue(numStr, unit);
      }
    }

    // 2.4 Tìm tên người nhận
    final nameReg = RegExp(
      r'(?:người\s*nhận|nguoi\s*nhan|chủ\s*tk|chu\s*tk|tên|ten|đến|den|tới|toi)\s*[:\-]?\s*([A-ZÀ-Ỹ\s]{3,35})',
      caseSensitive: false,
    );
    final nameMatch = nameReg.firstMatch(text);
    if (nameMatch != null) {
      final candidate = nameMatch.group(1)!.trim();
      // Loại bỏ các từ khóa thừa
      if (!candidate.toLowerCase().contains('ngan hang') &&
          !candidate.toLowerCase().contains('so tien')) {
        matchedRecipientName = candidate;
      }
    }

    // 2.5 Tìm nội dung chuyển tiền (ND, lời nhắn, memo)
    final noteReg = RegExp(
      r'(?:nội\s*dung|noi\s*dung|nd|lý\s*do|ly\s*do|lời\s*nhắn|loi\s*nhan|ghi\s*chú|ghi\s*chu|content|memo|msg)\s*[:\-]?\s*([^\n\r,;]+)',
      caseSensitive: false,
    );
    final noteMatch = noteReg.firstMatch(text);
    if (noteMatch != null) {
      matchedNote = noteMatch.group(1)!.trim();
    }

    final hasInfo = matchedAccount != null ||
        (matchedBankName != null && matchedAmount != null) ||
        (matchedAmount != null && matchedAmount > 0 && text.contains('chuyển'));

    return ParsedTransferData(
      accountNumber: matchedAccount,
      bankName: matchedBankName,
      bankBin: matchedBankBin,
      recipientName: matchedRecipientName,
      amount: matchedAmount,
      note: matchedNote,
      rawText: text,
      hasTransferInfo: hasInfo,
    );
  }

  /// Trích xuất cấu trúc EMVCo VietQR offline
  static ParsedTransferData? _parseEmvCo(String emv) {
    try {
      final Map<String, String> tags = _decodeTlv(emv);

      String? account;
      String? bankBin;
      double? amount;
      String? note;

      // Tag 54: Amount
      if (tags.containsKey('54')) {
        amount = double.tryParse(tags['54']!);
      } else {
        final amtMatch = RegExp(r'54(\d{2})(\d+)').firstMatch(emv);
        if (amtMatch != null) {
          final len = int.tryParse(amtMatch.group(1)!) ?? 0;
          final val = amtMatch.group(2)!;
          if (val.length >= len) {
            amount = double.tryParse(val.substring(0, len));
          }
        }
      }

      // Tag 62: Additional Data (Tag 08 trong tag 62 là mục đích/lời nhắn)
      if (tags.containsKey('62')) {
        final subTags62 = _decodeTlv(tags['62']!);
        if (subTags62.containsKey('08')) {
          note = subTags62['08'];
        }
      }
      if (note == null) {
        final noteMatch = RegExp(r'08(\d{2})([A-Za-z0-9\s]+)').firstMatch(emv);
        if (noteMatch != null) {
          final len = int.tryParse(noteMatch.group(1)!) ?? 0;
          final val = noteMatch.group(2)!;
          if (val.length >= len) {
            note = val.substring(0, len);
          }
        }
      }

      // Tag 38: Merchant Account Information (VietQR Napas)
      if (tags.containsKey('38')) {
        final subTags38 = _decodeTlv(tags['38']!);
        // Sub-tag 01 chứa Sub-sub-tag: 00 là Bank BIN, 01 là Account Number
        if (subTags38.containsKey('01')) {
          final subTags01 = _decodeTlv(subTags38['01']!);
          bankBin = subTags01['00'];
          account = subTags01['01'];
        }
      }

      // Fallback: nếu chưa lấy được account, bóc tách SĐT 10 số (tag 0110)
      if (account == null || account.isEmpty) {
        final tagMatch = RegExp(r'0110(0[35789]\d{8})').firstMatch(emv);
        if (tagMatch != null) {
          account = tagMatch.group(1);
        }
      }

      if (account != null && account.isNotEmpty) {
        String? bankName;
        if (bankBin != null) {
          for (final entry in _banks.values) {
            if (entry.$2 == bankBin) {
              bankName = entry.$1;
              break;
            }
          }
        }

        return ParsedTransferData(
          accountNumber: account,
          bankName: bankName ?? 'Napas 24/7',
          bankBin: bankBin,
          amount: amount,
          note: note,
          rawText: emv,
          hasTransferInfo: true,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Giải mã TLV (Tag-Length-Value) theo chuẩn EMVCo
  static Map<String, String> _decodeTlv(String input) {
    final Map<String, String> result = {};
    int idx = 0;
    while (idx + 4 <= input.length) {
      final tag = input.substring(idx, idx + 2);
      final len = int.tryParse(input.substring(idx + 2, idx + 4)) ?? -1;
      if (len < 0 || idx + 4 + len > input.length) break;
      final val = input.substring(idx + 4, idx + 4 + len);
      result[tag] = val;
      idx += 4 + len;
    }
    return result;
  }

  static double? _parseAmountValue(String numStr, String? unit) {
    var clean = numStr.replaceAll(' ', '');
    // Xử lý dấu chấm/phẩy kiểu Việt Nam
    if (clean.contains('.') && clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    final base = double.tryParse(clean);
    if (base == null) return null;

    if (unit == null) return base;

    switch (unit) {
      case 'k':
      case 'nghìn':
      case 'nghin':
        return base * 1000;
      case 'tr':
      case 'triệu':
      case 'trieu':
        return base * 1000000;
      case 'vnd':
      case 'đ':
      case 'd':
      default:
        return base;
    }
  }
}
