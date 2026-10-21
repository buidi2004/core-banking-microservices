/// Helper tiện ích chuẩn hóa việc bóc tách số tiền (amount), số dư cuối (endingBalance),
/// số tài khoản và nội dung cho thông báo biến động số dư (persisted & realtime).
/// Đáp ứng yêu cầu audit AUDIT-MOB-BE-06 (M-02, M-03).
class NotificationParser {
  NotificationParser._();

  /// Parse amount với đúng dấu âm/dương dựa trên metadata, payload type và body.
  /// Ưu tiên:
  /// 1. metadata['transactionAmount'] hoặc metadata['amount']
  /// 2. Áp dụng dấu dựa trên loại giao dịch:
  ///    - Deduct (trừ tiền ví): TRANSFER_OUT, WITHDRAWAL, PAYMENT, BILL_PAYMENT, TOPUP -> âm (-)
  ///    - Credit (cộng tiền ví): TRANSFER_IN, DEPOSIT, REVERSAL, REFUND -> dương (+)
  /// 3. Fallback regex `PS: [+-]...` trong nội dung thông báo nếu không có metadata hoặc amount = 0
  /// 4. Đảm bảo nguồn có fee (displayAmount = amount + fee) hiển thị đúng tổng tiền bị trừ.
  static double parseAmount({
    Map<String, dynamic>? metadata,
    String? body,
    String? type,
  }) {
    final normType = (type ?? metadata?['type'] ?? '').toString().trim().toUpperCase();
    final status = (metadata?['status'] ?? '').toString().trim().toUpperCase();
    final isReversal = status == 'REVERSED' || normType == 'REVERSAL' || normType == 'REFUND';

    final isDeduct = !isReversal &&
        (normType == 'TRANSFER_OUT' ||
            normType == 'WITHDRAWAL' ||
            normType == 'PAYMENT' ||
            normType == 'BILL_PAYMENT' ||
            normType == 'TOPUP');

    final isCredit = isReversal ||
        normType == 'TRANSFER_IN' ||
        normType == 'DEPOSIT';

    // 1. Kiểm tra metadata transactionAmount / amount
    final rawAmount = metadata?['transactionAmount'] ?? metadata?['amount'];
    double? parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount != null) {
      final str = rawAmount.toString().replaceAll('.', '').replaceAll(',', '').trim();
      parsedAmount = double.tryParse(str);
    }

    // 2. Kiểm tra regex PS: trong body
    RegExpMatch? psMatch;
    if (body != null && body.isNotEmpty) {
      psMatch = RegExp(r'PS:\s*([+-]?[\d.,]+)').firstMatch(body);
    }

    if (parsedAmount != null && parsedAmount != 0.0) {
      if (isDeduct) {
        return -parsedAmount.abs();
      } else if (isCredit) {
        return parsedAmount.abs();
      } else if (psMatch != null) {
        final matchedStr = psMatch.group(1)!;
        if (matchedStr.startsWith('-')) {
          return -parsedAmount.abs();
        } else if (matchedStr.startsWith('+')) {
          return parsedAmount.abs();
        }
      }
      return parsedAmount;
    }

    // Fallback: bóc tách từ body regex
    if (psMatch != null) {
      final clean = psMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(clean) ?? 0.0;
      if (val != 0.0) {
        if (isDeduct && val > 0) return -val;
        if (isCredit && val < 0) return val.abs();
        return val;
      }
    }

    return 0.0;
  }

  /// Parse số dư cuối từ body ("SD: 18.900.000 VND") hoặc metadata ("newBalance", "balanceAfter").
  static String? parseEndingBalance({
    Map<String, dynamic>? metadata,
    String? body,
  }) {
    if (body != null && body.isNotEmpty) {
      final sdMatch = RegExp(r'\bSD:\s*([\d.,]+)').firstMatch(body);
      if (sdMatch != null) {
        return sdMatch.group(1)?.replaceAll('.', '').replaceAll(',', '');
      }
    }
    final raw = metadata?['newBalance'] ?? metadata?['balanceAfter'] ?? metadata?['endingBalance'];
    if (raw != null) {
      return raw.toString().replaceAll('.', '').replaceAll(',', '').trim();
    }
    return null;
  }

  /// Parse số tài khoản từ body ("TK 0901234567") hoặc metadata ("accountNumber", "phoneNumber", "walletId").
  static String? parseAccountNumber({
    Map<String, dynamic>? metadata,
    String? body,
  }) {
    if (body != null && body.isNotEmpty) {
      final tkMatch = RegExp(r'\bTK\s+([^\s]+)').firstMatch(body);
      if (tkMatch != null) return tkMatch.group(1)?.trim();
    }
    final raw = metadata?['accountNumber'] ?? metadata?['phoneNumber'] ?? metadata?['walletId'];
    return raw?.toString();
  }

  /// Parse nội dung giao dịch từ body ("ND: ...") hoặc metadata ("note").
  static String? parseNote({
    Map<String, dynamic>? metadata,
    String? body,
  }) {
    if (body != null && body.isNotEmpty) {
      final ndMatch = RegExp(r'\bND:\s*([^\n]+)').firstMatch(body);
      if (ndMatch != null) return ndMatch.group(1)?.trim();
    }
    final raw = metadata?['note'] ?? metadata?['content'] ?? metadata?['desc'];
    return raw?.toString();
  }
}
