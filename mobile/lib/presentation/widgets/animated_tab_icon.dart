import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Các phân loại tab để áp dụng hiệu ứng chuyển động vi mô (Micro-animations) đặc thù
enum AnimatedTabType {
  home,
  cards,
  qr,
  gift,
  more,
  generic,
}

/// Widget icon tab tương tác vi mô: tự động nảy lò xo (Spring Bounce) và
/// chuyển động đặc thù (tilt, jiggle, roof bounce) khi người dùng chạm vào tab.
class AnimatedTabIcon extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final bool isSelected;
  final Color color;
  final AnimatedTabType tabType;
  final double size;

  const AnimatedTabIcon({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.isSelected,
    required this.color,
    this.tabType = AnimatedTabType.generic,
    this.size = 24.0,
  });

  @override
  State<AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<AnimatedTabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _semanticAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Chuỗi biến đổi kích thước đàn hồi (Elastic Scale: Co lại -> Bung to -> Cân bằng)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.82)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.82, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_controller);

    _semanticAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTabIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (oldWidget.isSelected && !widget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = (widget.isSelected && widget.selectedIcon != null)
        ? widget.selectedIcon!
        : widget.icon;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isSelected ? _scaleAnimation.value : 1.0;
        final t = _controller.value;

        Widget transformed = child!;

        switch (widget.tabType) {
          case AnimatedTabType.home:
            // Roof spring bounce: Mái nhà nhún nảy nhẹ lên trên 3.5dp
            final dy = -3.5 * math.sin(t * math.pi);
            transformed = Transform.translate(
              offset: Offset(0, dy),
              child: transformed,
            );
            break;

          case AnimatedTabType.cards:
            // Card swipe tilt: Nghiêng góc quẹt thẻ thanh toán 8 độ
            final angle = 0.12 * math.sin(t * math.pi);
            transformed = Transform.rotate(
              angle: angle,
              child: transformed,
            );
            break;

          case AnimatedTabType.gift:
            // Gift jiggle: Hộp quà lắc lư nắp 2 nhịp vui vẻ
            final angle = 0.14 * math.sin(t * 2 * math.pi);
            transformed = Transform.rotate(
              angle: angle,
              child: transformed,
            );
            break;

          case AnimatedTabType.more:
            // Grid 90-degree rotate: Xoay mở rộng lưới tiện ích
            final angle = (math.pi / 2) * _semanticAnimation.value;
            transformed = Transform.rotate(
              angle: angle,
              child: transformed,
            );
            break;

          case AnimatedTabType.qr:
          case AnimatedTabType.generic:
            // Scale pop mặc định
            break;
        }

        return Transform.scale(
          scale: scale,
          child: transformed,
        );
      },
      child: Icon(
        iconData,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
