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
  static const Color warningText = Color(0xFF7C2D12); // 6.0:1 (nâng từ #B45309 — 3.86:1)

  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFFB91C1C);

  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF166534); // 5.49:1 (nâng từ #15803D — 3.86:1)

  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoText = Color(0xFF1D4ED8);

  static const Color infoTealBg = Color(0xFFF0FDFA);
  static const Color infoTealBorder = Color(0xFF99F6E4);
  static const Color infoTealText = Color(0xFF0F766E);

  // Text Colors (Light Mode)
  // Lưu ý (AUDIT-TP-CONTRAST-001): nền app là ảnh SÁNG (#E0E2E1) và mọi
  // GlassCard ở chế độ sáng chỉ phủ lớp kính rất nhạt → bề mặt vẫn sáng.
  // Các token dưới đây đã hiệu chỉnh để đạt WCAG AA trên nền sáng:
  //   textPrimaryLight   13.7:1
  //   textSecondaryLight  5.8:1  (nâng từ #64748B — chỉ 3.66:1)
  //   textMutedLight     4.57:1  (nâng từ #94A3B8 — chỉ 2.56:1)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF55657A);

  // Màu nhấn dùng cho CHỮ trên nền sáng (WCAG AA ≥ 4.5:1).
  // AppColors.primary #00B4D8 chỉ đạt 2.46:1 → không dùng làm màu chữ.
  static const Color primaryText = Color(0xFF075985); // 5.8:1 (nền sáng) · 4.8:1 (nền xanh nhạt)
  // Xanh lá dạng chữ (emeraldGreen #10B981 chỉ đạt 1.95:1).
  static const Color successTextLight = Color(0xFF166534); // 5.49:1
  // Cam dạng chữ (warningText #B45309 chỉ đạt 3.86:1).
  static const Color warningTextLight = Color(0xFF7C2D12); // 6.0:1 (nền sáng) · 5.9:1 (nền cam nhạt)
  // Tím dạng chữ (softPurple #8B5CF6 chỉ đạt 3.25:1).
  static const Color softPurpleText = Color(0xFF6D28D9); // 6.32:1

  // Xanh lá sáng — dùng cho CHỮ/ICON trên nền TỐI (card công nghệ).
  static const Color emeraldGreenLight = Color(0xFF34D399); // 5.4:1 trên nền #36414E

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
