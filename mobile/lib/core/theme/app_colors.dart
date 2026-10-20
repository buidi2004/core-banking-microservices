import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Sen Hồng Brand Palette (Đồng bộ chuẩn xác với màu xanh của nút BottomBar)
  // Màu nút BottomBar: Cyan Ngọc Lam Color(0xFF26E5DC) & Oceanic Turquoise Color(0xFF00B4D8)
  static const Color primary = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF0077B6);
  static const Color primaryLight = Color(0xFF26E5DC);
  static const Color primaryAccent = Color(0xFF26E5DC);
  static const Color bottomBarCyan = Color(0xFF26E5DC);
  static const Color bottomBarOcean = Color(0xFF00B4D8);
  static const Color bottomBarGlow = Color(0xFF00E5FF);
  static const Color accentGold = Color(0xFFFFB300);

  // Secondary & Accents
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color vividTeal = Color(0xFF00BFA5);
  static const Color softPurple = Color(0xFF8B5CF6);
  static const Color oceanBlue = Color(0xFF0288D1);

  // Light Mode Surfaces (Chuyển sang trong suốt để hiển thị ảnh nền kính hoa văn)
  static const Color bgLight = Colors.transparent;
  static const Color bgSurfaceLight = Color(0xCCFFFFFF);
  static const Color cardLight = Color(0xD9FFFFFF);
  static const Color cardBorderLight = Color(0x66FFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Backgrounds & Surface (Dark Mode Fintech)
  static const Color bgDark = Colors.transparent;
  static const Color bgSurfaceDark = Color(0xCC131929);
  static const Color cardDark = Color(0xDD1A2238);
  static const Color cardBorderDark = Color(0x33FFFFFF);

  // Glassmorphism Tint Colors
  static const Color glassFillLight = Color(0xB8FFFFFF);
  static const Color glassBorderLight = Color(0x80FFFFFF);
  static const Color glassFillDark = Color(0x2A1E293B);
  static const Color glassBorderDark = Color(0x3DFFFFFF);

  // State & Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF00B4D8);

  // Status Surfaces & Accents (Thông báo, Cảnh báo, Trạng thái chuẩn hệ thống)
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFFB45309);

  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFFB91C1C);

  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);

  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoText = Color(0xFF1D4ED8);

  static const Color infoTealBg = Color(0xFFF0FDFA);
  static const Color infoTealBorder = Color(0xFF99F6E4);
  static const Color infoTealText = Color(0xFF0F766E);

  // Text Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Text Colors (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Gradients chuẩn sắc màu nút BottomBar
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF26E5DC), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bottomBarGradient = LinearGradient(
    colors: [Color(0xFF26E5DC), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient balanceCardGradient = LinearGradient(
    colors: [
      Color(0xFF023E8A),
      Color(0xFF0077B6),
      Color(0xFF0096C7),
      Color(0xFF26E5DC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGoldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardTitaniumGradient = LinearGradient(
    colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
