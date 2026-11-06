import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'app_colors.dart';
import '../../presentation/routes/smooth_page_transitions_builder.dart';

class AppTheme {
  AppTheme._();

  /// Font bundle cục bộ (assets/fonts + đăng ký trong pubspec.yaml).
  /// Dùng font bundle thay vì google_fonts runtime: offline 100%, không nháy
  /// chữ (FOUT) lần đầu mở app — chuẩn cho app ngân hàng.
  static const String fontFamily = 'Be Vietnam Pro';

  /// TextStyle tiện ích với font bundle — giữ tham số giống GoogleFonts.*
  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Typography chuẩn theo design system (Be Vietnam Pro / Plus Jakarta Sans)
  /// - Header nhóm: fontSize: 16, fontWeight: w700, màu #1A1A1A
  /// - Tiêu đề dòng: fontSize: 14.5, fontWeight: w600, màu #222222
  /// - Phụ đề: fontSize: 12.5, fontWeight: w400, màu #757575
  static TextTheme get _lightTextTheme {
    return ThemeData.light().textTheme.apply(fontFamily: fontFamily).copyWith(
          // AppBar title
          titleLarge: font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.2,
          ),
          // Header nhóm (section header)
          titleMedium: font(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.1,
          ),
          // Tiêu đề từng dòng
          titleSmall: font(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
            letterSpacing: -0.1,
          ),
          // Body text
          bodyLarge: font(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.05,
          ),
          bodyMedium: font(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryLight,
          ),
          bodySmall: font(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757575),
          ),
          // Label text
          labelLarge: font(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
          labelMedium: font(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
          labelSmall: font(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMutedLight,
            letterSpacing: 0.5,
          ),
        );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgSurfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
      ),
      textTheme: _lightTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: font(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      // Apple HIG minimum hit area for icon-only controls.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Primary dark surface keeps white CTA labels clearly readable.
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: AppColors.bottomBarGlow.withOpacity(0.45),
          textStyle: font(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: font(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: font(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF222222),
        ),
        subtitleTextStyle: font(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF757575),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothFintechPageTransitionsBuilder(),
          // iOS dùng transition gốc của Cupertino để giữ thao tác vuốt mép trái
          // (interactive pop gesture) — yêu cầu bắt buộc của Apple HIG.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothFintechPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothFintechPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothFintechPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme get _darkTextTheme {
    return ThemeData.light().textTheme.apply(fontFamily: fontFamily).copyWith(
          titleLarge: font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
          titleMedium: font(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
          titleSmall: font(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
          bodyLarge: font(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
          bodyMedium: font(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
          bodySmall: font(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryDark,
          ),
        );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgSurfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
      ),
      textTheme: _darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: font(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: AppColors.bottomBarGlow.withOpacity(0.45),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothFintechPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothFintechPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothFintechPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothFintechPageTransitionsBuilder(),
        },
      ),
    );
  }

  static GlassThemeData get glassTheme {
    return GlassThemeData.simple(
      blur: 10,
      thickness: 30,
      quality: GlassQuality.standard,
    );
  }

  /// Tối ưu scroll behavior cho trải nghiệm trượt mượt mà
  /// Hỗ trợ cả Android và iOS với physics phù hợp
  static ScrollBehavior get scrollBehavior {
    return const ScrollBehavior().copyWith(
      scrollbars: true,
      overscroll: true,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
    );
  }
}
