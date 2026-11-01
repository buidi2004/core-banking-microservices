import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Apple Human Interface Guidelines (HIG) Design Tokens.
/// Cung cấp các hằng số quy chuẩn về căn lề (Spacing), góc bo (Radius),
/// kích thước tương tác tối thiểu (Hit Target) và phản hồi xúc giác (Taptic Engine).
class AppleHigSpacing {
  AppleHigSpacing._();

  /// Lề chuẩn hệ thống iOS: 16pt (Margins for table views and standard layout)
  static const double standard = 16.0;

  /// Lề thu gọn iOS: 8pt (Compact spacing between related elements)
  static const double compact = 8.0;

  /// Lề siêu nhỏ: 4pt (Micro spacing)
  static const double micro = 4.0;

  /// Lề lớn iOS: 24pt (Section margins, sheet headers)
  static const double large = 24.0;

  /// Lề siêu lớn: 32pt (Hero sections, onboarding)
  static const double extraLarge = 32.0;

  /// Insets chuẩn theo Apple HIG
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listRowPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(8.0);

  /// Kích thước vùng bấm tối thiểu chuẩn ngón tay của Apple (44x44 pt)
  static const double minTouchTarget = 44.0;
  static const Size minTouchSize = Size(44.0, 44.0);

  /// Bán kính bo góc chuẩn iOS (Squircle-friendly)
  static const double radiusButton = 14.0;
  static const double radiusCard = 16.0;
  static const double radiusSheet = 24.0;
  static const double radiusSquircle = 20.0;
  static const double radiusIcon = 12.0;
  static const double radiusPill = 999.0;
}

/// Hệ thống quản lý phản hồi xúc giác Apple Taptic Engine (Haptics)
class AppHaptics {
  AppHaptics._();

  /// Rung chạm nhẹ (Selection Click) — dùng khi đổi Tab, gạt công tắc, chọn item
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Tác động nhẹ (Light Impact) — dùng khi nhấn phím số bàn phím PIN, nút phụ
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Tác động vừa (Medium Impact) — dùng khi nhấn nút CTA chính, mở Sheet
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Tác động mạnh (Heavy Impact) — dùng khi thực hiện tác vụ quan trọng / xóa dữ liệu
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Cảnh báo thành công (Apple Pay Success) — 2 nhịp gõ tinh tế
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Cảnh báo lỗi (Error / Validation Failure) — rung giật báo động
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Cảnh báo thận trọng (Warning)
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
  }
}

/// Tiện ích phân giải màu ngữ nghĩa thích ứng Light / Dark Mode chuẩn Apple
class AppleSemanticColors {
  AppleSemanticColors._();

  /// Nền chính hệ thống
  static Color systemBackground(BuildContext context) =>
      CupertinoColors.systemBackground.resolveFrom(context);

  /// Nền thứ cấp cho nhóm Inset Grouped List
  static Color secondarySystemGroupedBackground(BuildContext context) =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

  /// Nền nhóm chính Inset Grouped List
  static Color systemGroupedBackground(BuildContext context) =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);

  /// Nhãn chính (Chữ chính)
  static Color label(BuildContext context) =>
      CupertinoColors.label.resolveFrom(context);

  /// Nhãn thứ cấp (Phụ đề, ngày tháng)
  static Color secondaryLabel(BuildContext context) =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  /// Nhãn mờ (Tertiary label)
  static Color tertiaryLabel(BuildContext context) =>
      CupertinoColors.tertiaryLabel.resolveFrom(context);

  /// Đường phân cách ngăn giữa các dòng (Separator)
  static Color separator(BuildContext context) =>
      CupertinoColors.separator.resolveFrom(context);

  /// Xanh dương Apple hệ thống (System Blue)
  static Color systemBlue(BuildContext context) =>
      CupertinoColors.systemBlue.resolveFrom(context);

  /// Xanh lá thành công Apple hệ thống (System Green)
  static Color systemGreen(BuildContext context) =>
      CupertinoColors.systemGreen.resolveFrom(context);

  /// Đỏ lỗi Apple hệ thống (System Red)
  static Color systemRed(BuildContext context) =>
      CupertinoColors.systemRed.resolveFrom(context);
}
