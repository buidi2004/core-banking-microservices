import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final NumberFormat _vndFormatWithSymbolName = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  static String formatVND(num amount) {
    return _vndFormat.format(amount);
  }

  static String formatVNDWithCode(num amount) {
    return _vndFormatWithSymbolName.format(amount);
  }

  static String formatMasked(num amount, bool isMasked) {
    if (isMasked) {
      return '****** đ';
    }
    return formatVND(amount);
  }

  static String toVietnameseWords(num amount) {
    int n = amount.toInt();
    if (n <= 0) return '';

    const units = ['', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ'];
    const digits = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];

    String readGroup(int group, bool showZeroHundred) {
      int h = group ~/ 100;
      int t = (group % 100) ~/ 10;
      int u = group % 10;
      String res = '';

      if (h > 0 || showZeroHundred) {
        res += '${digits[h]} trăm ';
      }

      if (t == 0 && u > 0) {
        if (h > 0 || showZeroHundred) res += 'lẻ ';
        res += digits[u];
      } else if (t == 1) {
        res += 'mười ';
        if (u == 1) {
          res += 'một';
        } else if (u == 5) {
          res += 'lăm';
        } else if (u > 0) {
          res += digits[u];
        }
      } else if (t > 1) {
        res += '${digits[t]} mươi ';
        if (u == 1) {
          res += 'mốt';
        } else if (u == 4) {
          res += 'tư';
        } else if (u == 5) {
          res += 'lăm';
        } else if (u > 0) {
          res += digits[u];
        }
      }

      return res.trim();
    }

    List<int> groups = [];
    int temp = n;
    while (temp > 0) {
      groups.add(temp % 1000);
      temp ~/= 1000;
    }

    String result = '';
    for (int i = groups.length - 1; i >= 0; i--) {
      int g = groups[i];
      if (g == 0) continue;
      bool showZeroHundred = (i < groups.length - 1);
      String groupStr = readGroup(g, showZeroHundred);
      if (groupStr.isNotEmpty) {
        result += '$groupStr ${units[i]} ';
      }
    }

    result = result.trim();
    if (result.isEmpty) return '';
    result = '${result[0].toUpperCase()}${result.substring(1)} đồng';
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }
}
