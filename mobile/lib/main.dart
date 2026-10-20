import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'core/network/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/widgets/floating_notification_hud.dart';
import 'presentation/widgets/user_avatar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp avatar đã lưu trong bộ nhớ an toàn
  await UserAvatarNotifier.init();

  // Pre-warm fragment shader để tránh hiện tượng nháy trắng (warmup jank) lần đầu
  await LiquidGlassWidgets.initialize();

  // Khởi chạy ứng dụng ngay lập tức để render Splash Screen hoa sen nở không độ trễ
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality: true, // Cho phép tự động điều chỉnh chất lượng phù hợp với hiệu năng thiết bị
      theme: AppTheme.glassTheme,
      child: const SenHongApp(),
    ),
  );

  // Nạp quyền thiết bị & dịch vụ FCM ngầm song song sau khi frame đầu tiên đã vẽ
  _initBackgroundServices();
}

void _initBackgroundServices() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Không xin quyền hệ thống tại đây để tránh làm phiền người dùng lúc mở app
    // Quyền hệ thống sẽ được xin sau khi người dùng hoàn tất đăng nhập hoặc đăng ký
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint('Không thể khởi tạo PushNotificationService: $e');
    }
  });
}

class SenHongApp extends StatelessWidget {
  const SenHongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sen Hồng Bank',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      scrollBehavior: const SmoothFintechScrollBehavior(),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh nền tách thành const widget riêng — không bị tạo lại khi route thay đổi
            const _AppBackground(),
            // Các màn hình hiển thị đè lên trên ảnh nền kèm Thông báo nổi toàn app
            GlobalFloatingNotificationOverlay(
              child: Material(
                type: MaterialType.transparency,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget ảnh nền toàn màn hình — tách riêng và dùng const
/// để Flutter không tạo lại mỗi lần builder của MaterialApp.router chạy.
class _AppBackground extends StatelessWidget {
  const _AppBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/glass_background_pattern.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// Tùy chỉnh hiệu ứng cuộn mượt mà chuẩn ngân hàng cao cấp,
/// sử dụng BouncingScrollPhysics loại bỏ hoàn toàn hiện tượng khựng cứng/clamping giật cục
class SmoothFintechScrollBehavior extends MaterialScrollBehavior {
  const SmoothFintechScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
