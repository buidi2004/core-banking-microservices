import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTypography — tất cả base style được cache dưới dạng static final.
/// Mỗi lần gọi chỉ chạy copyWith(color:) thay vì tạo TextStyle hoàn toàn mới,
/// giảm đáng kể allocation trên heap khi build() chạy lại.
class AppTypography {
  AppTypography._();

  // ── Cached base styles ──────────────────────────────────────────────────
  static final _displayLargeBase = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  static final _displayMediumBase = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static final _displaySmallBase = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static final _titleLargeBase = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static final _titleMediumBase = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static final _titleSmallBase = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static final _bodyLargeBase = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  static final _bodyMediumBase = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  static final _bodySmallBase = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static final _labelLargeBase = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static final _balanceTextBase = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // ── Apple HIG Hierarchy cached base styles ──────────────────────────────
  static final _largeTitleBase = GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
  );
  static final _title1Base = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.36,
  );
  static final _title2Base = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );
  static final _title3Base = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
  );
  static final _headlineBase = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
  );
  static final _bodyBase = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );
  static final _calloutBase = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
  );
  static final _subheadlineBase = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );
  static final _footnoteBase = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );
  static final _caption1Base = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
  );
  static final _caption2Base = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
  );

  // ── Public API — chỉ copyWith khi cần đổi color ─────────────────────────
  static TextStyle displayLarge({Color? color}) => color == null
      ? _displayLargeBase
      : _displayLargeBase.copyWith(color: color);

  static TextStyle displayMedium({Color? color}) => color == null
      ? _displayMediumBase
      : _displayMediumBase.copyWith(color: color);

  static TextStyle displaySmall({Color? color}) => color == null
      ? _displaySmallBase
      : _displaySmallBase.copyWith(color: color);

  static TextStyle titleLarge({Color? color}) =>
      color == null ? _titleLargeBase : _titleLargeBase.copyWith(color: color);

  static TextStyle titleMedium({Color? color}) => color == null
      ? _titleMediumBase
      : _titleMediumBase.copyWith(color: color);

  static TextStyle titleSmall({Color? color}) =>
      color == null ? _titleSmallBase : _titleSmallBase.copyWith(color: color);

  static TextStyle bodyLarge({Color? color}) =>
      color == null ? _bodyLargeBase : _bodyLargeBase.copyWith(color: color);

  static TextStyle bodyMedium({Color? color}) =>
      color == null ? _bodyMediumBase : _bodyMediumBase.copyWith(color: color);

  static TextStyle bodySmall({Color? color}) =>
      color == null ? _bodySmallBase : _bodySmallBase.copyWith(color: color);

  static TextStyle labelLarge({Color? color}) =>
      color == null ? _labelLargeBase : _labelLargeBase.copyWith(color: color);

  static TextStyle balanceText({Color? color}) => color == null
      ? _balanceTextBase
      : _balanceTextBase.copyWith(color: color);

  // ── Apple HIG Named Typography API ──────────────────────────────────────
  /// Apple HIG Large Title (34pt, Bold)
  static TextStyle largeTitle({Color? color}) =>
      color == null ? _largeTitleBase : _largeTitleBase.copyWith(color: color);

  /// Apple HIG Title 1 (28pt, Semibold)
  static TextStyle title1({Color? color}) =>
      color == null ? _title1Base : _title1Base.copyWith(color: color);

  /// Apple HIG Title 2 (22pt, Semibold)
  static TextStyle title2({Color? color}) =>
      color == null ? _title2Base : _title2Base.copyWith(color: color);

  /// Apple HIG Title 3 (20pt, Semibold)
  static TextStyle title3({Color? color}) =>
      color == null ? _title3Base : _title3Base.copyWith(color: color);

  /// Apple HIG Headline (17pt, Semibold)
  static TextStyle headline({Color? color}) =>
      color == null ? _headlineBase : _headlineBase.copyWith(color: color);

  /// Apple HIG Body (17pt, Regular)
  static TextStyle body({Color? color}) =>
      color == null ? _bodyBase : _bodyBase.copyWith(color: color);

  /// Apple HIG Callout (16pt, Regular)
  static TextStyle callout({Color? color}) =>
      color == null ? _calloutBase : _calloutBase.copyWith(color: color);

  /// Apple HIG Subheadline (15pt, Regular)
  static TextStyle subheadline({Color? color}) =>
      color == null ? _subheadlineBase : _subheadlineBase.copyWith(color: color);

  /// Apple HIG Footnote (13pt, Regular)
  static TextStyle footnote({Color? color}) =>
      color == null ? _footnoteBase : _footnoteBase.copyWith(color: color);

  /// Apple HIG Caption 1 (12pt, Medium)
  static TextStyle caption1({Color? color}) =>
      color == null ? _caption1Base : _caption1Base.copyWith(color: color);

  /// Apple HIG Caption 2 (11pt, Regular)
  static TextStyle caption2({Color? color}) =>
      color == null ? _caption2Base : _caption2Base.copyWith(color: color);
}
