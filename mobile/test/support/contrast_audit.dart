import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// ---------------------------------------------------------------------------
/// Bộ công cụ Audit tương phản (contrast) cho màn hình Flutter.
///
/// Mục tiêu: phát hiện lỗi "phản quan" (chữ sáng trên nền sáng) và "chữ bị mờ"
/// (tương phản < WCAG AA) trong các luồng nghiệp vụ, dựa trên màu nền THỰC TẾ
/// mà người dùng nhìn thấy.
///
/// Nguyên lý:
///  1. App Sen Hồng chạy 100% ở chế độ SÁNG (`AppTheme.lightTheme`) và nền ảnh
///     `assets/images/glass_background_pattern.png` có màu trung bình ~#E0E2E1.
///  2. `GlassCard` ở chế độ sáng chỉ phủ một lớp kính rất nhạt
///     (`Color.fromRGBO(210,220,240,0.12)`) → bề mặt vẫn SÁNG.
///  3. Vì vậy mọi chữ màu trắng / trắng mờ nằm trên GlassCard đều vô đọc.
///
/// Công thức tương phản theo WCAG 2.1 (relative luminance).
/// ---------------------------------------------------------------------------

/// Màu nền ảnh toàn app đo được từ `assets/images/glass_background_pattern.png`
/// (trung bình RGB 224,5 / 226,7 / 224,9).
const Color kAppBackgroundLight = Color(0xFFE0E2E1);

/// Lớp kính (liquid glass) ở chế độ sáng: `Color.fromRGBO(210, 220, 240, 0.12)`.
const Color kGlassLightTint = Color(0x1FD2DCF0);

/// Ngưỡng WCAG AA.
const double kAaNormalText = 4.5;
const double kAaLargeText = 3.0;

/// Ngưỡng "phản quan" — chữ sáng trên nền sáng, tương phản < 2.0 thì coi như
/// không đọc được (đây là nguyên nhân gốc của "phản quan" trong app).
const double kReversedContrastThreshold = 2.0;

/// Ngưỡng WCAG 1.4.11 cho nội dung phi chữ (icon/graphic có ý nghĩa).
const double kNonTextContrastThreshold = 3.0;

/// Kết quả audit cho một thành phần chữ.
class TextContrastFinding {
  const TextContrastFinding({
    required this.text,
    required this.color,
    required this.background,
    required this.ratio,
    required this.fontSize,
    required this.bold,
    required this.threshold,
  });

  final String text;

  /// Màu chữ đã authored (có thể kèm alpha).
  final Color color;

  /// Màu nền hiệu dụng sau khi composite tất cả lớp nền cha.
  final Color background;

  /// Tỉ lệ tương phản WCAG.
  final double ratio;
  final double fontSize;
  final bool bold;

  /// Ngưỡng AA áp dụng (3.0 nếu là chữ lớn, 4.5 nếu chữ thường).
  final double threshold;

  bool get passesAa => ratio >= threshold;

  /// Chữ sáng trên nền sáng → "phản quan".
  bool get isReversed =>
      ratio < kReversedContrastThreshold &&
      color.computeLuminance() > background.computeLuminance();

  /// Chữ quá mờ (tương phản thấp nhưng không hẳn là phản quan).
  bool get isFaded => !isReversed && ratio < threshold;

  @override
  String toString() {
    final flag = isReversed ? 'PHẢN-QUAN' : (isFaded ? 'MỜ' : 'OK');
    return '[$flag] ratio=${ratio.toStringAsFixed(2)} (>=${threshold.toStringAsFixed(1)}) '
        'size=${fontSize.toStringAsFixed(1)}${bold ? ' bold' : ''} '
        'fg=#${color.toARGB32().toRadixString(16).padLeft(8, '0')} '
        'bg=#${background.toARGB32().toRadixString(16).padLeft(8, '0')} '
        '"${text.length > 44 ? '${text.substring(0, 44)}…' : text}"';
  }
}

/// Kết quả audit cho một ICON (WCAG 1.4.11 — yêu cầu ≥ 3:1).
class IconContrastFinding {
  const IconContrastFinding({
    required this.icon,
    required this.color,
    required this.background,
    required this.ratio,
    required this.size,
  });

  final IconData? icon;
  final Color color;
  final Color background;
  final double ratio;
  final double size;

  bool get passes => ratio >= kNonTextContrastThreshold;

  /// Icon sáng trên nền sáng → bị "phản quan" (gần như vô hình).
  bool get isReversed =>
      ratio < kReversedContrastThreshold &&
      color.computeLuminance() > background.computeLuminance();

  @override
  String toString() {
    final flag = isReversed ? 'PHẢN-QUAN' : (passes ? 'OK' : 'MỜ');
    return '[$flag] icon ratio=${ratio.toStringAsFixed(2)} (>=3.0) size=${size.toStringAsFixed(0)} '
        'fg=#${color.toARGB32().toRadixString(16).padLeft(8, '0')} '
        'bg=#${background.toARGB32().toRadixString(16).padLeft(8, '0')} '
        '"${icon.toString()}"';
  }
}

/// Trộn màu `fg` (có alpha) lên trên nền `bg`.
Color compositeOver(Color fg, Color bg) {
  final a = fg.a;
  if (a >= 1.0) return fg;
  return Color.from(
    alpha: 1.0,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
}

/// Tỉ lệ tương phản WCAG giữa hai màu đã opaque.
double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

/// Trả về màu nền mà widget này vẽ ra (nếu có).
Color? _paintedColor(Widget w) {
  if (w is ColoredBox) return w.color;
  if (w is DecoratedBox) {
    final decoration = w.decoration;
    if (decoration is! BoxDecoration) return null;
    if (decoration.color != null) return decoration.color;
    // Gradient: dùng màu trung bình của các stop (xấp xỉ tốt cho text trên
    // gradient như nút tab / nút nhấn). Phải giữ cả alpha để lớp kính/gradient
    // nửa trong suốt được composite đúng với nền phía dưới.
    final gradient = decoration.gradient;
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
      for (final c in gradient.colors) {
        r += c.r;
        g += c.g;
        b += c.b;
        a += c.a;
      }
      final n = gradient.colors.length;
      return Color.from(
        alpha: a / n,
        red: r / n,
        green: g / n,
        blue: b / n,
      );
    }
    return null;
  }
  if (w is Material) {
    if (w.type == MaterialType.transparency) return null;
    return w.color;
  }
  if (w is Scaffold) return w.backgroundColor;
  if (w is AppBar) return w.backgroundColor;
  // GlassCard ở chế độ sáng = lớp kính nhạt phủ trên nền.
  if (w is GlassCard) return kGlassLightTint;
  return null;
}

/// Tính màu nền hiệu dụng cho một element (composite từ ngoài vào trong).
Color resolveEffectiveBackground(Element element,
    {Color base = kAppBackgroundLight}) {
  final layers = <Color>[];
  element.visitAncestorElements((ancestor) {
    final c = _paintedColor(ancestor.widget);
    if (c != null) layers.add(c);
    return true;
  });
  var bg = base;
  for (final layer in layers.reversed) {
    bg = compositeOver(layer, bg);
  }
  return bg;
}

/// Bọc màn hình vào môi trường giống hệt app thật: theme sáng + nền ảnh sáng.
Widget auditHarness(Widget screen, {Color background = kAppBackgroundLight}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    home: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        screen,
      ],
    ),
  );
}

/// Thu thập mọi thành phần chữ đang hiển thị và tính tương phản.
List<TextContrastFinding> collectTextFindings(WidgetTester tester) {
  final findings = <TextContrastFinding>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final rawText = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    if (rawText.trim().isEmpty) continue;

    final defaultStyle = DefaultTextStyle.of(element).style;
    final style = defaultStyle.merge(widget.style);
    final color = style.color ?? const Color(0xFF000000);
    final bg = resolveEffectiveBackground(element);
    final effectiveFg = compositeOver(color, bg);
    final ratio = contrastRatio(effectiveFg, bg);

    final fontSize = style.fontSize ?? defaultStyle.fontSize ?? 14;
    final weight = style.fontWeight ?? defaultStyle.fontWeight ?? FontWeight.normal;
    final bold = weight.index >= FontWeight.w600.index;
    final isLarge = fontSize >= 24 || (fontSize >= 18.66 && bold);
    final threshold = isLarge ? kAaLargeText : kAaNormalText;

    findings.add(
      TextContrastFinding(
        text: rawText,
        color: color,
        background: bg,
        ratio: ratio,
        fontSize: fontSize,
        bold: bold,
        threshold: threshold,
      ),
    );
  }
  return findings;
}

/// Thu thập mọi ICON đang hiển thị và tính tương phản phi chữ (WCAG 1.4.11).
List<IconContrastFinding> collectIconFindings(WidgetTester tester) {
  final findings = <IconContrastFinding>[];
  for (final element in find.byType(Icon).evaluate()) {
    final widget = element.widget as Icon;
    final color = widget.color;
    if (color == null) continue; // Icon mặc định lấy từ IconTheme.
    final bg = resolveEffectiveBackground(element);
    final effectiveFg = compositeOver(color, bg);
    final ratio = contrastRatio(effectiveFg, bg);
    findings.add(
      IconContrastFinding(
        icon: widget.icon,
        color: color,
        background: bg,
        ratio: ratio,
        size: widget.size ?? 24,
      ),
    );
  }
  return findings;
}

/// In báo cáo audit ra console (dùng để thu thập bằng chứng).
void printContrastReport(
  String screenName,
  List<TextContrastFinding> findings, {
  bool onlyProblems = true,
}) {
  // ignore: avoid_print
  print('\n=== AUDIT CONTRAST: $screenName ===');
  final sorted = [...findings]..sort((a, b) => a.ratio.compareTo(b.ratio));
  var issues = 0;
  for (final f in sorted) {
    if (onlyProblems && f.passesAa) continue;
    issues++;
    // ignore: avoid_print
    print('  $f');
  }
  if (onlyProblems && issues == 0) {
    // ignore: avoid_print
    print('  (không phát hiện vấn đề tương phản)');
  }
  // ignore: avoid_print
  print('  -> tổng chữ: ${findings.length}, vấn đề: $issues');
}

/// In báo cáo audit icon ra console.
void printIconReport(
  String screenName,
  List<IconContrastFinding> findings, {
  bool onlyProblems = true,
}) {
  // ignore: avoid_print
  print('\n=== AUDIT ICON CONTRAST: $screenName ===');
  final sorted = [...findings]..sort((a, b) => a.ratio.compareTo(b.ratio));
  var issues = 0;
  for (final f in sorted) {
    if (onlyProblems && f.passes) continue;
    issues++;
    // ignore: avoid_print
    print('  $f');
  }
  if (onlyProblems && issues == 0) {
    // ignore: avoid_print
    print('  (không phát hiện vấn đề tương phản icon)');
  }
  // ignore: avoid_print
  print('  -> tổng icon: ${findings.length}, vấn đề: $issues');
}

/// Đếm số finding không đạt WCAG AA.
int countAaFailures(List<TextContrastFinding> findings) =>
    findings.where((f) => !f.passesAa).length;

/// Đếm số finding bị "phản quan" (chữ sáng trên nền sáng).
int countReversed(List<TextContrastFinding> findings) =>
    findings.where((f) => f.isReversed).length;

/// Đếm số icon bị "phản quan" / mờ.
int countIconReversed(List<IconContrastFinding> findings) =>
    findings.where((f) => f.isReversed).length;

/// Đếm số icon không đạt WCAG 1.4.11.
int countIconProblems(List<IconContrastFinding> findings) =>
    findings.where((f) => !f.passes).length;
