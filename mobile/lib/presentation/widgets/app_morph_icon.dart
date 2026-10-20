import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morphnext/morphnext.dart';

/// Widget hỗ trợ chuyển đổi icon dạng vector (Vector Morphing) mượt mà bằng thư viện morphnext.
/// Tự động sinh hiệu ứng biến đổi hình học (morphing animation) giữa hai icon bất kỳ khi icon thay đổi.
class AppMorphIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final SpringDescription spring;
  final VoidCallback? onEnd;

  const AppMorphIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.spring = MorphSprings.snappy,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedMorphIcon(
      icon: icon,
      size: size,
      color: color,
      spring: spring,
      onEnd: onEnd,
    );
  }
}

/// Nút toggle ẩn/hiện (Mắt xem mật khẩu, mắt xem số dư tài khoản)
/// Sử dụng morphnext để morph mượt mà giữa Icon Mở Mắt và Đóng Mắt.
class MorphEyeButton extends StatelessWidget {
  final bool isHidden;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const MorphEyeButton({
    super.key,
    required this.isHidden,
    required this.onTap,
    this.size = 20,
    this.color,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: padding,
      constraints: const BoxConstraints(),
      icon: AnimatedMorphIcon(
        icon: isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: size,
        color: color,
        spring: MorphSprings.snappy,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
