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
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static final _bodyLargeBase = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.normal,
  );
  static final _bodyMediumBase = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  static final _bodySmallBase = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
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

  // ── Public API — chỉ copyWith khi cần đổi color ─────────────────────────
  static TextStyle displayLarge({Color? color}) =>
      color == null ? _displayLargeBase : _displayLargeBase.copyWith(color: color);

  static TextStyle displayMedium({Color? color}) =>
      color == null ? _displayMediumBase : _displayMediumBase.copyWith(color: color);

  static TextStyle displaySmall({Color? color}) =>
      color == null ? _displaySmallBase : _displaySmallBase.copyWith(color: color);

  static TextStyle titleLarge({Color? color}) =>
      color == null ? _titleLargeBase : _titleLargeBase.copyWith(color: color);

  static TextStyle titleMedium({Color? color}) =>
      color == null ? _titleMediumBase : _titleMediumBase.copyWith(color: color);

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

  static TextStyle balanceText({Color? color}) =>
      color == null ? _balanceTextBase : _balanceTextBase.copyWith(color: color);
}
