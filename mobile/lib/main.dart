import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'core/network/dio_client.dart';
import 'core/network/push_notification_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/widgets/floating_notification_hud.dart';
import 'presentation/widgets/user_avatar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khôi phục địa chỉ Gateway (Local / GitHub Codespaces) đã lưu nếu có
  await DioClient.initSavedGateway();

  // Nạp avatar đã lưu trong bộ nhớ an toàn
  await UserAvatarNotifier.init();

  // Pre-warm fragment shader để tránh hiện tượng nháy trắng (warmup jank) lần đầu
  await LiquidGlassWidgets.initialize();

  // Khởi chạy ứng dụng ngay lập tức để render Splash Screen hoa sen nở không độ trễ
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality:
          true, // Cho phép tự động điều chỉnh chất lượng phù hợp với hiệu năng thiết bị
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

class SenHongApp extends StatefulWidget {
  const SenHongApp({super.key});

  @override
  State<SenHongApp> createState() => _SenHongAppState();
}

class _SenHongAppState extends State<SenHongApp> with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Apple Financial Security: Khi người dùng vuốt mở App Switcher hoặc khóa màn hình,
    // tự động che mờ (Privacy Blur) toàn bộ nội dung số dư và giao dịch tài chính.
    final shouldBlur = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused;
    if (shouldBlur != _isBackgrounded && mounted) {
      setState(() => _isBackgrounded = shouldBlur);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sen Hồng Bank',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // App dựng trên nền ảnh sáng cố định (Liquid Glass) nên chốt giao diện Sáng,
      // tránh hệ thống tự đổi Dark Mode làm mất tương phản toàn bộ màn hình.
      themeMode: ThemeMode.light,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      scrollBehavior: const SmoothFintechScrollBehavior(),
      builder: (context, child) {
        final routePath = appRouter.routeInformationProvider.value.uri.path;
        final lightSurface = routePath != '/' &&
            routePath != '/splash' &&
            routePath != '/scan-qr';
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              lightSurface ? Brightness.dark : Brightness.light,
          statusBarBrightness:
              lightSurface ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        );
        SystemChrome.setSystemUIOverlayStyle(overlayStyle);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Stack(
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
              // Apple Privacy Protection Blur Screen (App Switcher)
              if (_isBackgrounded)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: Colors.white.withOpacity(0.88),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Bảo Mật Ngân Hàng Số',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Dữ liệu giao dịch được mã hóa an toàn',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
