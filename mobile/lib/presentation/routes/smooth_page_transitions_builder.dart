import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bộ chuyển trang cao cấp chuẩn Apple Fintech (Apple Fluid Deceleration + Spatial Depth Parallax):
/// - Chuyển động êm ái, nhịp độ vừa phải (Cinematic Smooth Pacing) để cảm nhận rõ độ sâu không gian
/// - Màn hình mới trượt vào kết hợp dải đổ bóng quang học mép trái (Edge Drop Shadow)
/// - Màn hình cũ lùi thị sai (Slide Out -10%), co nhẹ chiều sâu 3D (Scale 0.94) và mờ nhẹ (Opacity 0.80)
/// - Đường cong chuyển động Cubic(0.16, 1.0, 0.3, 1.0) chuẩn Apple thế hệ mới: êm mượt, không giật cục
class SmoothFintechPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothFintechPageTransitionsBuilder();

  // Đường cong gia tốc chuyển động mượt mà êm dịu (Fluid Smooth Deceleration)
  static const Curve _fluidCurve = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primaryCurve = CurvedAnimation(
      parent: animation,
      curve: _fluidCurve,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _fluidCurve,
      reverseCurve: Curves.easeInCubic,
    );

    // 1. Màn hình mới tiến vào: Trượt từ phải 30% + Fade in từ 0.10 lên 1.0
    final slideIn = Tween<Offset>(
      begin: const Offset(0.30, 0.0),
      end: Offset.zero,
    ).animate(primaryCurve);

    final fadeIn = Tween<double>(
      begin: 0.10,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    ));

    // 2. Màn hình cũ lùi về sau (Spatial Depth Push-Back):
    // Trượt lùi -10% + Co nhẹ về 0.94 + Mờ nhẹ xuống 80%
    final parallaxSlideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.10, 0.0),
    ).animate(secondaryCurve);

    final parallaxScaleOut = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(secondaryCurve);

    final parallaxFadeOut = Tween<double>(
      begin: 1.0,
      end: 0.80,
    ).animate(secondaryCurve);

    return SlideTransition(
      position: parallaxSlideOut,
      child: ScaleTransition(
        scale: parallaxScaleOut,
        child: FadeTransition(
          opacity: parallaxFadeOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  child,
                  // Đổ bóng quang học mép trái tạo cảm giác chiều sâu nổi khối
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 18,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.14),
                              Colors.black.withOpacity(0.04),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Các kiểu chuyển trang tùy biến chuyên sâu cho các tác vụ đặc biệt (Bottom Sheet, QR, Tìm kiếm, Hoàn tất)
abstract final class AppPageTransitions {
  // Đường cong chuyển động êm dịu đồng nhất cho toàn app
  static const Curve fluidCurve = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Hiệu ứng mở Tìm kiếm (Search Transition):
  /// Nhịp độ 460ms chậm rãi, mượt mà kết hợp trượt nhẹ 10% từ dưới lên và phóng nhẹ (0.96 -> 1.0)
  static Page<T> searchTransition<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 460),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: fluidCurve,
          reverseCurve: Curves.easeInCubic,
        );

        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.10),
          end: Offset.zero,
        ).animate(curve);

        final scale = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).animate(curve);

        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
        ));

        return SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: scale,
            child: FadeTransition(
              opacity: fade,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Hiệu ứng trượt từ dưới lên (Modal Slide Up) cho QR Scanner, My QR, Bộ lọc
  static Page<T> modalSlideUp<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 460),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: fluidCurve,
          reverseCurve: Curves.easeInCubic,
        );

        final slideUp = Tween<Offset>(
          begin: const Offset(0.0, 0.28),
          end: Offset.zero,
        ).animate(curve);

        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        ));

        final scaleIn = Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(curve);

        return SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fadeIn,
            child: ScaleTransition(
              scale: scaleIn,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Hiệu ứng Phóng to & Hòa tan (Celebration Zoom) cho màn hình hoàn tất giao dịch
  static Page<T> celebrationZoom<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        final scale = Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).animate(curve);

        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
        ));

        return ScaleTransition(
          scale: scale,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        );
      },
    );
  }
}
