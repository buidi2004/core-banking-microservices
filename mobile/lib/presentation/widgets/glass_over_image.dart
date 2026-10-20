import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Widget tổng quát triển khai kiến trúc kính 3 lớp độc lập (3-Tier Sibling Stack Architecture):
///
/// ┌────────────────────────────────────────────────────────┐
/// │  Layer 3: NỘI DUNG (Foreground Content)                │
/// │  - Text, Icons, Buttons, Form, Cards... SẮC NÉT 100%   │
/// │  - Nhận tương tác cảm ứng trực tiếp (Touch / Gestures)  │
/// ├────────────────────────────────────────────────────────┤
/// │  Layer 2: LỚP KÍNH MỜ (Optical Glass Backdrop)         │
/// │  - BackdropFilter (blurSigma, tintOpacity, border)     │
/// │  - Chỉ làm nền quang học, KHÔNG chứa nội dung bên trong│
/// ├────────────────────────────────────────────────────────┤
/// │  Layer 1: ẢNH NỀN / SCENE GỐC (Backdrop Layer)         │
/// │  - Image.asset, Image.network, hoặc background widget  │
/// └────────────────────────────────────────────────────────┘
///
/// Tái sử dụng linh hoạt ở mọi vị trí trong app: Card nổi trên ảnh, Hero banner,
/// header, modal dialog, màn hình đăng nhập...
class GlassOverImage extends StatelessWidget {
  /// Widget nền ở Layer 1 (nếu truyền vào trực tiếp widget tùy biến)
  final Widget? background;

  /// Đường dẫn asset ảnh nền (nếu sử dụng ảnh asset cục bộ)
  final String? imagePath;

  /// Đường dẫn URL ảnh nền từ mạng (nếu sử dụng network image)
  final String? imageUrl;

  /// Cách co giãn hiển thị ảnh nền
  final BoxFit fit;

  /// Nội dung hiển thị ở Layer 3 (sắc nét 100%, không bị blur)
  final Widget content;

  /// Độ mờ quang học Gaussian blur của lớp kính mờ (Layer 2)
  final double blurSigma;

  /// Độ đục của lớp màu phủ kính (Layer 2)
  final double tintOpacity;

  /// Màu sắc của lớp phủ kính (mặc định là trắng)
  final Color tintColor;

  /// Bo góc cho toàn bộ khối kính và ảnh nền
  final BorderRadius? borderRadius;

  /// Viền ngoài tùy biến (mặc định là viền trắng mờ thanh mảnh 0.8px)
  final BoxBorder? border;

  /// Chiều rộng khối (tùy chọn)
  final double? width;

  /// Chiều cao khối (tùy chọn)
  final double? height;

  /// Padding bên trong cho nội dung Layer 3
  final EdgeInsetsGeometry? padding;

  const GlassOverImage({
    super.key,
    this.background,
    this.imagePath,
    this.imageUrl,
    this.fit = BoxFit.cover,
    required this.content,
    this.blurSigma = 20.0,
    this.tintOpacity = 0.35,
    this.tintColor = Colors.white,
    this.borderRadius,
    this.border,
    this.width,
    this.height,
    this.padding,
  });

  /// Factory constructor tiện lợi dùng cho ảnh Asset
  factory GlassOverImage.asset({
    Key? key,
    required String imagePath,
    required Widget content,
    BoxFit fit = BoxFit.cover,
    double blurSigma = 20.0,
    double tintOpacity = 0.35,
    Color tintColor = Colors.white,
    BorderRadius? borderRadius,
    BoxBorder? border,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassOverImage(
      key: key,
      imagePath: imagePath,
      fit: fit,
      content: content,
      blurSigma: blurSigma,
      tintOpacity: tintOpacity,
      tintColor: tintColor,
      borderRadius: borderRadius,
      border: border,
      width: width,
      height: height,
      padding: padding,
    );
  }

  /// Factory constructor tiện lợi dùng cho ảnh Network từ URL
  factory GlassOverImage.network({
    Key? key,
    required String imageUrl,
    required Widget content,
    BoxFit fit = BoxFit.cover,
    double blurSigma = 20.0,
    double tintOpacity = 0.35,
    Color tintColor = Colors.white,
    BorderRadius? borderRadius,
    BoxBorder? border,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassOverImage(
      key: key,
      imageUrl: imageUrl,
      fit: fit,
      content: content,
      blurSigma: blurSigma,
      tintOpacity: tintOpacity,
      tintColor: tintColor,
      borderRadius: borderRadius,
      border: border,
      width: width,
      height: height,
      padding: padding,
    );
  }

  Widget _buildBackground() {
    if (background != null) {
      return background!;
    }
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.cardDark,
        ),
      );
    }
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.cardDark,
        ),
      );
    }
    return Container(
      color: AppColors.cardDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget stack = Stack(
      fit: StackFit.passthrough,
      children: [
        // ──────────────────────────────────────────────────────────
        // LAYER 1: ẢNH NỀN / SCENE GỐC (Dưới cùng)
        // ──────────────────────────────────────────────────────────
        Positioned.fill(
          child: _buildBackground(),
        ),

        // ──────────────────────────────────────────────────────────
        // LAYER 2: LỚP KÍNH MỜ (Ở giữa - CHỈ blur + tint, không có con)
        // ──────────────────────────────────────────────────────────
        Positioned.fill(
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  color: tintColor.withOpacity(tintOpacity),
                  borderRadius: borderRadius,
                  border: border ??
                      Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 0.8,
                      ),
                ),
              ),
            ),
          ),
        ),

        // ──────────────────────────────────────────────────────────
        // LAYER 3: NỘI DUNG (Trên cùng - SẮC NÉT 100%, không bị blur)
        // ──────────────────────────────────────────────────────────
        if (padding != null)
          Padding(
            padding: padding!,
            child: content,
          )
        else
          content,
      ],
    );

    if (borderRadius != null) {
      stack = ClipRRect(
        borderRadius: borderRadius!,
        child: stack,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: stack,
      );
    }

    return stack;
  }
}
