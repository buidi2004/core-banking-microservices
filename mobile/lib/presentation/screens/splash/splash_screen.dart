import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/core/storage/app_session.dart';

/// Màn hình khởi động (Splash Screen) đa tầng đạt chuẩn điện ảnh 60 FPS cho SenBank.
///
/// Hoạt cảnh 5 Giây (5000ms) Sinh Trưởng & Nở Hoa Tự Nhiên (Natural Biological Blooming):
/// - Giai đoạn 1 (0 – 1250ms): Nền hồ đêm tĩnh lặng, 7 chữ cái SENBANK tự vẽ kèm hiệu ứng nổi khối 3D vươn lên và dải hạt sáng.
/// - Giai đoạn 2 (1250 – 2500ms): Mầm sen nảy mầm từ mặt nước, cuống sen vươn dài dẻo dai từ lòng hồ, búp sen nhô mặt nước, sóng nước 3D gợn tỏa đồng tâm.
/// - Giai đoạn 3 (2375 – 3000ms): Búp sen hé nụ, hai lá đài ngoài từ từ tách hé mở ra hai bên, hé lộ cánh hoa ngọc bên trong.
/// - Giai đoạn 4 (3000 – 4250ms): 20 cánh hoa sen bung nở đều đặn tự nhiên 360 độ qua 4 tầng, đài gương sen 9 mắt & 20 tua nhụy ngọc bung tỏa rực rỡ.
/// - Nhịp chốt đỉnh cao (4250ms): Cánh hoa chạm độ nở 100%, kích hoạt chùm sáng flash bừng sáng trên chữ SENBANK nổi khối và đóa sen.
/// - Giữ khung hình vương giả thiền định (4250 – 4700ms): Giữ trọn vẹn biểu tượng hoàn mỹ cho người dùng cảm thụ.
/// - Giai đoạn kết thúc (4700 – 5000ms): ScaleTransition 1.00 -> 1.04 & FadeTransition hòa tan êm ái vào trang chính.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // SpringSimulation vật lý chuẩn xác cho quá trình mầm sen vươn trồi
  static final SpringSimulation _stemSpring = SpringSimulation(
    const SpringDescription(mass: 1.0, stiffness: 140.0, damping: 19.0),
    0.0,
    1.0,
    0.0,
  );

  // Sub-animation cho Pha thoát màn hình (FadeTransition & ScaleTransition trên Compositor Layer)
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  bool _isNavigating = false;
  bool _isLoggedIn = false;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // Khởi tạo animations thoát màn hình êm ái ở 300ms cuối (Interval 0.940 -> 1.000)
    _exitScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.940, 1.000, curve: Curves.easeInOutCubic),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.940, 1.000, curve: Curves.easeInOutCubic),
      ),
    );

    // Warm-up 1 frame để GPU biên dịch trước shader, loại bỏ hoàn toàn giật ở frame đầu
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      SchedulerBinding.instance.scheduleWarmUpFrame();
    }

    // Prefetch token ngầm ngay trong lúc hoạt ảnh diễn ra
    _prefetchAuthStatus();

    _controller.forward().then((_) {
      _navigateToNextScreen();
    });
  }

  Future<void> _prefetchAuthStatus() async {
    try {
      const storage = AppSecureStorage.instance;
      final token = await AppSecureStorage.safeRead(storage, key: AppConstants.keyAccessToken);
      if (token != null && token.isNotEmpty) {
        if (_isJwtExpired(token)) {
          // Token cũ đã hết hạn, chủ động dọn dẹp và đánh dấu sessionExpired để hiển thị rõ thông báo yêu cầu đăng nhập
          await AppSecureStorage.safeDelete(storage, key: AppConstants.keyAccessToken);
          await AppSecureStorage.safeDelete(storage, key: AppConstants.keyRefreshToken);
          _isLoggedIn = false;
          _sessionExpired = true;
        } else {
          _isLoggedIn = true;
          _sessionExpired = false;
        }
      } else {
        _isLoggedIn = false;
        _sessionExpired = false;
      }
    } catch (_) {
      _isLoggedIn = false;
      _sessionExpired = false;
    }
  }

  /// Tiền kiểm tra thời hạn của AccessToken (JWT) để tránh chuyển vào Home khi token đã hết hạn
  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Chuẩn hóa padding Base64Url trước khi giải mã
      final payloadNormalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadNormalized));
      final Map<String, dynamic> payloadMap = json.decode(payloadString);

      if (!payloadMap.containsKey('exp')) return false;

      final exp = payloadMap['exp'];
      if (exp is! num) return false;

      final expSeconds = exp.toInt();
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Dành 5 giây an toàn (safety buffer)
      return nowSeconds >= (expSeconds - 5);
    } catch (_) {
      return true;
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    try {
      if (_isLoggedIn && AppSession.unlocked) {
        context.go('/');
      } else {
        if (_sessionExpired) {
          context.go('/auth/login?sessionExpired=true');
        } else {
          context.go('/auth/login');
        }
      }
    } catch (_) {
      // Hỗ trợ môi trường test widget độc lập hoặc khi router đang tái khởi tạo
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.cardDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cardDark,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToNextScreen, // Chạm để vào app tức thì
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ===============================================================
              // LAYER 1: NỀN TĨNH HỒ ĐÊM HOÀNG GIA (RepaintBoundary - 0% repaint)
              // ===============================================================
              const RepaintBoundary(
                child: _StaticBackgroundLayer(),
              ),

              // ===============================================================
              // LAYER 2: NỘI DUNG CHÍNH (ScaleTransition & FadeTransition cho Exit)
              // ===============================================================
              ScaleTransition(
                scale: _exitScale,
                child: FadeTransition(
                  opacity: _exitOpacity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A. SÓNG NƯỚC MẶT HỒ ĐỒNG TÂM PHỐI CẢNH 3D (1000ms -> 3800ms)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => CustomPaint(
                            painter: _WaterRipplesPainter(
                              currentMs: _controller.value * 4000.0,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),

                      // B. ĐÓA SEN 20 CÁNH & 20 NHỤY SEN & NẢY MẦM TỰ NHIÊN (1000ms -> 3400ms)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => CustomPaint(
                            painter: _LotusBloomPainter(
                              currentMs: _controller.value * 4000.0,
                              stemSpring: _stemSpring,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),

                      // C. TYPOGRAPHY "SENBANK" NỔI KHỐI 3D + FLASH CHỐT 3400MS (200ms -> 3600ms)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => CustomPaint(
                            painter: _SenBankTextPainter(
                              currentMs: _controller.value * 4000.0,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),

                      // D. DẢI HẠT SÁNG THEO NÉT CHỮ O(1) (200ms -> 1200ms)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => CustomPaint(
                            painter: _LightParticlesPainter(
                              currentMs: _controller.value * 4000.0,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LAYER 1: STATIC BACKGROUND (Không repaint - 0% raster cost)
// =============================================================================
class _StaticBackgroundLayer extends StatelessWidget {
  const _StaticBackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.45,
          colors: [
            AppColors.primaryDark,
            AppColors.cardDark,
            AppColors.bgSurfaceDark,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _SubtleBackgroundRaysPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _SubtleBackgroundRaysPainter extends CustomPainter {
  static final Paint _rayPaint = Paint()
    ..color = AppColors.primaryLight.withOpacity(0.04)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.33);
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, 95.0 * i, _rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// LAYER 2A: SÓNG NƯỚC HỒ ĐỒNG TÂM PHỐI CẢNH 3D (1000ms -> 3800ms)
// =============================================================================
class _WaterRipplesPainter extends CustomPainter {
  final double currentMs;

  _WaterRipplesPainter({required this.currentMs});

  static final Paint _wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _causticPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

  static final Paint _mistPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (currentMs < 1000.0) return;

    // Mặt nước tiếp xúc chân cuống sen (y = 0.33 * H + 130 = ~0.47 * H)
    final waterCenter = Offset(size.width / 2, size.height * 0.33 + 130.0);

    // 1. Ánh sáng lân tinh huyền ảo nơi cuống sen rẽ nước vươn lên
    final mistProgress = ((currentMs - 1000.0) / 900.0).clamp(0.0, 1.0);
    final mistOpacity = (0.35 * mistProgress) *
        (currentMs > 3400.0 ? (1.0 - (currentMs - 3400.0) / 600.0).clamp(0.0, 1.0) : 1.0);
    if (mistOpacity > 0.0) {
      _mistPaint.color = AppColors.bottomBarGlow.withOpacity(mistOpacity * 0.45);
      canvas.drawOval(
        Rect.fromCenter(center: waterCenter, width: 100.0, height: 30.0),
        _mistPaint,
      );
    }

    // 2. 7 đợt sóng nước đồng tâm hình elip lan tỏa theo phối cảnh mặt hồ
    const waveOrigins = [1000.0, 1280.0, 1560.0, 1840.0, 2120.0, 2400.0, 2700.0];
    const waveLife = 850.0;

    for (int i = 0; i < waveOrigins.length; i++) {
      final origin = waveOrigins[i];
      if (currentMs < origin) continue;

      final age = currentMs - origin;
      if (age > waveLife) continue;

      final progress = age / waveLife;
      final easedP = Curves.easeOutQuad.transform(progress);

      // Bán kính sóng mở rộng dần ra xa (phối cảnh dẹt mặt hồ ry = rx * 0.28)
      final rx = 18.0 + easedP * 155.0;
      final ry = rx * 0.28;

      // Độ mờ sóng nước giảm dần khi lan ra xa
      final waveAlpha = (1.0 - progress) * 0.65;
      if (waveAlpha <= 0.0) continue;

      final rect = Rect.fromCenter(center: waterCenter, width: rx * 2, height: ry * 2);

      // Quầng ánh nước ngọc lam
      _causticPaint.color = AppColors.bottomBarGlow.withOpacity(waveAlpha * 0.40);
      _causticPaint.strokeWidth = 3.5 * (1.0 - progress * 0.6);
      canvas.drawOval(rect, _causticPaint);

      // Gợn sóng chính viền ngọc sáng
      _wavePaint.color = AppColors.primaryLight.withOpacity(waveAlpha * 0.70);
      _wavePaint.strokeWidth = 1.6 * (1.0 - progress * 0.5);
      canvas.drawOval(rect, _wavePaint);

      // Điểm phản chiếu ánh trăng lấp lánh trên đỉnh gợn sóng
      if (progress < 0.6) {
        _wavePaint.color = Colors.white.withOpacity(waveAlpha * 0.50);
        _wavePaint.strokeWidth = 1.0;
        final highlightRect = Rect.fromCenter(center: waterCenter, width: rx * 1.6, height: ry * 1.6);
        canvas.drawArc(highlightRect, -0.4, 0.8, false, _wavePaint);
        canvas.drawArc(highlightRect, math.pi - 0.4, 0.8, false, _wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRipplesPainter oldDelegate) {
    final isActive = currentMs >= 1000.0 && currentMs <= 3800.0;
    final wasActive = oldDelegate.currentMs >= 1000.0 && oldDelegate.currentMs <= 3800.0;
    return isActive || wasActive;
  }
}

// =============================================================================
// LAYER 2B: DẢI HẠT SÁNG BÁM THEO NÉT VẼ CHỮ (200ms -> 1200ms)
// =============================================================================
class _LightParticlesPainter extends CustomPainter {
  final double currentMs;

  _LightParticlesPainter({
    required this.currentMs,
  });

  static final Paint _corePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (currentMs < 200.0 || currentMs > 1200.0) return;

    final textCenter = Offset(size.width / 2, size.height * 0.64);
    final letters = _SenBankTextPainter.letters;

    // Mỗi ký tự phát sinh tối đa 4 đốm sáng bám theo đầu nét vẽ (tổng đồng thời <= 12-14 hạt)
    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      for (int k = 0; k < 4; k++) {
        final spawnFraction = (k + 1) / 4.0;
        final birthMs = letter.startMs + spawnFraction * 180.0;
        final age = currentMs - birthMs;

        if (age >= 0.0 && age <= 200.0) {
          final progress = age / 200.0;
          final opacity = Curves.easeOut.transform(1.0 - progress);
          final radius = (2.2 - progress * 0.7);

          // Vị trí sinh ra tại đúng đầu nét vẽ
          final curvedP = Curves.easeOutCubic.transform(spawnFraction);
          final tip = letter.getTipAt(curvedP);

          // Độ trôi hạt vi mô nhẹ nhàng tự nhiên
          final driftX = math.sin(i * 3.7 + k * 1.9) * (progress * 6.0);
          final driftY = -math.cos(i * 2.1 + k * 2.7) * (progress * 5.0);

          // Đồng bộ độ cao nổi lên của chữ (vươn nổi 12px từ dưới lên)
          final letterElevateP = ((currentMs - letter.startMs) / 220.0).clamp(0.0, 1.0);
          final curvedRise = Curves.easeOutCubic.transform(letterElevateP);
          final elevateY = (1.0 - curvedRise) * 12.0;

          final pos = Offset(
            textCenter.dx + tip.dx + driftX,
            textCenter.dy + tip.dy + elevateY + driftY,
          );

          // Lõi trắng
          _corePaint.color = Colors.white.withOpacity(opacity);
          canvas.drawCircle(pos, radius, _corePaint);

          // Quầng hào quang ngọc lam cyan
          _glowPaint.color = AppColors.bottomBarGlow.withOpacity(opacity * 0.45);
          canvas.drawCircle(pos, radius * 1.8, _glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LightParticlesPainter oldDelegate) {
    final isActive = currentMs >= 200.0 && currentMs <= 1200.0;
    final wasActive = oldDelegate.currentMs >= 200.0 && oldDelegate.currentMs <= 1200.0;
    return isActive || wasActive;
  }
}

// =============================================================================
// LAYER 2C: CHỮ "SENBANK" NỔI KHỐI 3D + FLASH SÁNG CHỐT (200ms -> 3600ms)
// =============================================================================
class _SenBankTextPainter extends CustomPainter {
  final double currentMs;

  _SenBankTextPainter({
    required this.currentMs,
  });

  static List<_LetterGeometry> get letters => _letters;
  static final List<_LetterGeometry> _letters = _buildLettersGeometry();

  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

  static final Paint _flarePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  static List<_LetterGeometry> _buildLettersGeometry() {
    const double letterW = 28.0;
    const double letterH = 34.0;
    const double spacing = 11.0;
    const int count = 7;
    const double totalW = count * letterW + (count - 1) * spacing;
    const double startX = -totalW / 2;

    final List<_LetterGeometry> list = [];
    const List<String> chars = ['S', 'E', 'N', 'B', 'A', 'N', 'K'];

    for (int i = 0; i < count; i++) {
      final x = startX + i * (letterW + spacing);
      const y = -letterH / 2;
      final path = _createLetterPath(chars[i], x, y, letterW, letterH);
      final metrics = path.computeMetrics().toList();
      final totalLen = metrics.fold<double>(0.0, (sum, m) => sum + m.length);
      final startMs = 200.0 + i * 50.0;
      final endMs = startMs + 180.0;

      list.add(_LetterGeometry(
        char: chars[i],
        path: path,
        metrics: metrics,
        totalLength: totalLen,
        startMs: startMs,
        endMs: endMs,
      ));
    }
    return list;
  }

  static Path _createLetterPath(String char, double x, double y, double w, double h) {
    final path = Path();
    switch (char) {
      case 'S':
        path.moveTo(x + w * 0.88, y + h * 0.16);
        path.cubicTo(x + w * 0.80, y, x + w * 0.15, y, x + w * 0.12, y + h * 0.28);
        path.cubicTo(x + w * 0.10, y + h * 0.48, x + w * 0.45, y + h * 0.50, x + w * 0.60, y + h * 0.54);
        path.cubicTo(x + w * 0.92, y + h * 0.60, x + w * 0.90, y + h * 0.82, x + w * 0.84, y + h * 0.88);
        path.cubicTo(x + w * 0.75, y + h, x + w * 0.15, y + h, x + w * 0.10, y + h * 0.84);
        break;
      case 'E':
        path.moveTo(x + w * 0.88, y);
        path.lineTo(x + w * 0.12, y);
        path.lineTo(x + w * 0.12, y + h);
        path.lineTo(x + w * 0.88, y + h);
        path.moveTo(x + w * 0.12, y + h * 0.50);
        path.lineTo(x + w * 0.72, y + h * 0.50);
        break;
      case 'N':
        path.moveTo(x + w * 0.12, y + h);
        path.lineTo(x + w * 0.12, y);
        path.lineTo(x + w * 0.88, y + h);
        path.lineTo(x + w * 0.88, y);
        break;
      case 'B':
        path.moveTo(x + w * 0.12, y + h);
        path.lineTo(x + w * 0.12, y);
        path.lineTo(x + w * 0.55, y);
        path.cubicTo(x + w * 0.92, y, x + w * 0.92, y + h * 0.48, x + w * 0.55, y + h * 0.48);
        path.lineTo(x + w * 0.12, y + h * 0.48);
        path.moveTo(x + w * 0.55, y + h * 0.48);
        path.cubicTo(x + w * 0.96, y + h * 0.48, x + w * 0.96, y + h, x + w * 0.55, y + h);
        path.lineTo(x + w * 0.12, y + h);
        break;
      case 'A':
        path.moveTo(x + w * 0.08, y + h);
        path.lineTo(x + w * 0.50, y);
        path.lineTo(x + w * 0.92, y + h);
        path.moveTo(x + w * 0.24, y + h * 0.65);
        path.lineTo(x + w * 0.76, y + h * 0.65);
        break;
      case 'K':
        path.moveTo(x + w * 0.12, y);
        path.lineTo(x + w * 0.12, y + h);
        path.moveTo(x + w * 0.88, y);
        path.lineTo(x + w * 0.14, y + h * 0.52);
        path.lineTo(x + w * 0.88, y + h);
        break;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (currentMs < 200.0) return;

    final textCenter = Offset(size.width / 2, size.height * 0.64);
    canvas.save();
    canvas.translate(textCenter.dx, textCenter.dy);

    // Tính toán flash sáng tại đúng mốc 3400ms (nhịp chốt hoa sen nở rộ 100%)
    double flashAlpha = 0.0;
    if (currentMs >= 3400.0 && currentMs <= 3600.0) {
      if (currentMs < 3480.0) {
        flashAlpha = Curves.easeIn.transform((currentMs - 3400.0) / 80.0);
      } else {
        flashAlpha = Curves.easeOut.transform(1.0 - (currentMs - 3480.0) / 120.0);
      }
    }

    for (final letter in _letters) {
      if (currentMs < letter.startMs) continue;

      final p = ((currentMs - letter.startMs) / 180.0).clamp(0.0, 1.0);
      final curvedP = Curves.easeOutCubic.transform(p);

      // Hiệu ứng chữ nổi 3D: từ vị trí chìm sâu hơn 12px vươn nổi lên bề mặt
      final riseP = ((currentMs - letter.startMs) / 220.0).clamp(0.0, 1.0);
      final curvedRise = Curves.easeOutCubic.transform(riseP);
      final elevateY = (1.0 - curvedRise) * 12.0;
      final letterScale = 0.90 + 0.10 * curvedRise;

      canvas.save();
      canvas.translate(0, elevateY);
      canvas.scale(letterScale, letterScale);

      // 1. Lớp đổ bóng dập nổi 3D phía dưới chân chữ
      if (curvedRise > 0.0) {
        _shadowPaint.color = AppColors.bgSurfaceDark.withOpacity(curvedRise * 0.70);
        canvas.drawPath(letter.path.shift(const Offset(0, 3.0)), _shadowPaint);
      }

      // 2. Chữ hoặc nét vẽ
      if (curvedP >= 1.0) {
        // Chữ đã hoàn thành nét vẽ
        _strokePaint.color = Colors.white;
        canvas.drawPath(letter.path, _strokePaint);

        // Flash sáng chốt nhịp tại 3400ms
        if (flashAlpha > 0.0) {
          _glowPaint.color = AppColors.bottomBarGlow.withOpacity(flashAlpha * 0.90);
          canvas.drawPath(letter.path, _glowPaint);

          _strokePaint.color = Colors.white;
          canvas.drawPath(letter.path, _strokePaint);
        }
      } else {
        // Đang vẽ nét (Stroke Draw)
        final targetLength = letter.totalLength * curvedP;
        double accumulated = 0.0;

        for (final m in letter.metrics) {
          if (accumulated + m.length <= targetLength) {
            final sub = m.extractPath(0.0, m.length);
            _strokePaint.color = Colors.white;
            canvas.drawPath(sub, _strokePaint);
            accumulated += m.length;
          } else {
            final remain = targetLength - accumulated;
            final sub = m.extractPath(0.0, remain);
            _strokePaint.color = Colors.white;
            canvas.drawPath(sub, _strokePaint);
            break;
          }
        }
      }

      canvas.restore();
    }

    // Flash chùm sáng ngang qua cả chữ SENBANK tại nhịp 3400ms
    if (flashAlpha > 0.0) {
      _flarePaint.color = Colors.white.withOpacity(flashAlpha * 0.85);
      canvas.drawLine(const Offset(-145, 0), const Offset(145, 0), _flarePaint);

      // Tia sáng chéo lấp lánh (star sheen)
      final starPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.bottomBarGlow.withOpacity(flashAlpha * 0.90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawLine(const Offset(-40, -12), const Offset(40, 12), starPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SenBankTextPainter oldDelegate) {
    final inDrawPhase = currentMs >= 200.0 && currentMs <= 1000.0;
    final inFlashPhase = currentMs >= 3400.0 && currentMs <= 3600.0;
    final wasInDraw = oldDelegate.currentMs >= 200.0 && oldDelegate.currentMs <= 1000.0;
    final wasInFlash = oldDelegate.currentMs >= 3400.0 && oldDelegate.currentMs <= 3600.0;
    return inDrawPhase || inFlashPhase || wasInDraw || wasInFlash;
  }
}

class _LetterGeometry {
  final String char;
  final Path path;
  final List<PathMetric> metrics;
  final double totalLength;
  final double startMs;
  final double endMs;

  _LetterGeometry({
    required this.char,
    required this.path,
    required this.metrics,
    required this.totalLength,
    required this.startMs,
    required this.endMs,
  });

  /// Truy xuất toạ độ đầu nét vẽ tức thời O(1) không tốn chi phí tính toán lại
  Offset getTipAt(double curvedP) {
    if (totalLength <= 0.0) return Offset.zero;
    final targetLength = totalLength * curvedP.clamp(0.0, 1.0);
    double accumulated = 0.0;
    for (final m in metrics) {
      if (accumulated + m.length >= targetLength) {
        final remain = targetLength - accumulated;
        return m.getTangentForOffset(remain)?.position ?? Offset.zero;
      }
      accumulated += m.length;
    }
    return Offset.zero;
  }
}

// =============================================================================
// LAYER 2D: ĐÓA SEN 20 CÁNH & 20 NHỤY SEN & NẢY MẦM TỰ NHIÊN (1000ms -> 3400ms)
// =============================================================================
class _LotusBloomPainter extends CustomPainter {
  final double currentMs;
  final SpringSimulation stemSpring;

  _LotusBloomPainter({
    required this.currentMs,
    required this.stemSpring,
  });

  static final Path _stemPath = _buildStemPath();
  static final List<PathMetric> _stemMetrics = _stemPath.computeMetrics().toList();
  static final double _stemTotalLength =
      _stemMetrics.fold<double>(0.0, (sum, m) => sum + m.length);

  static final Path _closedBudPath = _buildClosedBudPath();
  static final Path _leftSepalPath = _buildLeftSepalPath();
  static final Path _rightSepalPath = _buildRightSepalPath();
  static final List<_PetalSpec> _petals = _buildPetalSpecs();

  static final Paint _stemPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round;

  static final Paint _budPetalPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = const LinearGradient(
      colors: [AppColors.primary, Colors.white],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-35, -115, 70, 115));

  static final Paint _sepalPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = const LinearGradient(
      colors: [AppColors.primaryDark, AppColors.primaryLight],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-35, -80, 70, 80));

  static final Paint _petalFillPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _petalBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = Colors.white.withOpacity(0.55);

  static final Paint _petalVeinPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..color = Colors.white.withOpacity(0.38);

  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  static final Paint _coreRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = AppColors.primaryLight;

  static final Paint _filamentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  static final Paint _antherPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  static final Paint _seedSpotPaint = Paint()
    ..style = PaintingStyle.fill;

  static final Paint _coreGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

  /// Bắt đầu từ đáy mặt nước (0, 130) vươn ngược lên tâm đóa sen (0, 0)
  static Path _buildStemPath() {
    final p = Path();
    p.moveTo(0, 130);
    p.cubicTo(8, 90, -6, 45, 0, 0);
    return p;
  }

  static Path _buildClosedBudPath() {
    final p = Path();
    p.moveTo(0, 0);
    p.cubicTo(-26, -30, -32, -85, 0, -118);
    p.cubicTo(32, -85, 26, -30, 0, 0);
    p.close();
    return p;
  }

  static Path _buildLeftSepalPath() {
    final p = Path();
    p.moveTo(0, 0);
    p.cubicTo(-28, -20, -36, -55, -8, -80);
    p.cubicTo(-4, -55, -2, -25, 0, 0);
    p.close();
    return p;
  }

  static Path _buildRightSepalPath() {
    final p = Path();
    p.moveTo(0, 0);
    p.cubicTo(28, -20, 36, -55, 8, -80);
    p.cubicTo(4, -55, 2, -25, 0, 0);
    p.close();
    return p;
  }

  static List<_PetalSpec> _buildPetalSpecs() {
    final list = <_PetalSpec>[];

    // Shaders tiền biên dịch 4 tầng từ ngoài vào trong
    final shader0 = const LinearGradient(
      colors: [AppColors.primaryDark, AppColors.primary],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-55, -165, 110, 165));

    final shader1 = const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-50, -150, 100, 150));

    final shader2 = const LinearGradient(
      colors: [AppColors.primaryLight, Colors.white],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-45, -135, 90, 135));

    final shader3 = const LinearGradient(
      colors: [Colors.white, AppColors.primaryLight],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(const Rect.fromLTWH(-40, -100, 80, 100));

    // =========================================================================
    // TẦNG 0: LÁ ĐÀI & CÁNH LƯNG SAU (5 cánh - Bắt đầu nở từ 2400ms đến 3050ms)
    // =========================================================================
    for (final angle in [-0.78, 0.78]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(68, 138, tipCurvature: angle > 0 ? 1.0 : -1.0),
        veinPath: _createPetalVeinsPath(68, 138),
        pathHeight: 138.0,
        baseAngle: angle,
        startMs: 2400.0,
        durationMs: 650.0,
        shader: shader0,
      ));
    }
    for (final angle in [-0.42, 0.42]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(70, 148, tipCurvature: angle > 0 ? 0.6 : -0.6),
        veinPath: _createPetalVeinsPath(70, 148),
        pathHeight: 148.0,
        baseAngle: angle,
        startMs: 2400.0,
        durationMs: 650.0,
        shader: shader0,
      ));
    }
    list.add(_PetalSpec(
      path: _createRealisticPetalPath(76, 160),
      veinPath: _createPetalVeinsPath(76, 160),
      pathHeight: 160.0,
      baseAngle: 0.0,
      startMs: 2400.0,
      durationMs: 650.0,
      shader: shader0,
    ));

    // =========================================================================
    // TẦNG 1: CÁNH HÔNG GIỮA (6 cánh - Lệch 120ms -> 2520ms đến 3170ms)
    // =========================================================================
    for (final angle in [-1.08, 1.08]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(64, 128, tipCurvature: angle > 0 ? 1.4 : -1.4),
        veinPath: _createPetalVeinsPath(64, 128),
        pathHeight: 128.0,
        baseAngle: angle,
        startMs: 2520.0,
        durationMs: 650.0,
        shader: shader1,
      ));
    }
    for (final angle in [-0.64, 0.64]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(66, 136, tipCurvature: angle > 0 ? 0.8 : -0.8),
        veinPath: _createPetalVeinsPath(66, 136),
        pathHeight: 136.0,
        baseAngle: angle,
        startMs: 2520.0,
        durationMs: 650.0,
        shader: shader1,
      ));
    }
    for (final angle in [-0.28, 0.28]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(68, 142, tipCurvature: angle > 0 ? 0.4 : -0.4),
        veinPath: _createPetalVeinsPath(68, 142),
        pathHeight: 142.0,
        baseAngle: angle,
        startMs: 2520.0,
        durationMs: 650.0,
        shader: shader1,
      ));
    }

    // =========================================================================
    // TẦNG 2: CÁNH TRƯỚC ÔM LÒNG CHẢO (5 cánh - Lệch 120ms -> 2640ms đến 3290ms)
    // =========================================================================
    for (final angle in [-0.54, 0.54]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(60, 122, tipCurvature: angle > 0 ? 0.6 : -0.6),
        veinPath: _createPetalVeinsPath(60, 122),
        pathHeight: 122.0,
        baseAngle: angle,
        startMs: 2640.0,
        durationMs: 650.0,
        shader: shader2,
      ));
    }
    for (final angle in [-0.26, 0.26]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(62, 118, tipCurvature: angle > 0 ? 0.3 : -0.3),
        veinPath: _createPetalVeinsPath(62, 118),
        pathHeight: 118.0,
        baseAngle: angle,
        startMs: 2640.0,
        durationMs: 650.0,
        shader: shader2,
      ));
    }
    list.add(_PetalSpec(
      path: _createRealisticPetalPath(64, 108),
      veinPath: _createPetalVeinsPath(64, 108),
      pathHeight: 108.0,
      baseAngle: 0.0,
      startMs: 2640.0,
      durationMs: 650.0,
      shader: shader2,
    ));

    // =========================================================================
    // TẦNG 3: CÁNH CON ÔM NHỤY & ĐÀI GƯƠNG SEN (4 cánh - Lệch 120ms -> 2760ms)
    // Chạm đích hoàn hảo đúng 3400ms! (2760 + 640 = 3400ms)
    // =========================================================================
    for (final angle in [-0.36, 0.36]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(46, 92, tipCurvature: angle > 0 ? 0.2 : -0.2),
        veinPath: _createPetalVeinsPath(46, 92),
        pathHeight: 92.0,
        baseAngle: angle,
        startMs: 2760.0,
        durationMs: 640.0,
        shader: shader3,
      ));
    }
    for (final angle in [-0.14, 0.14]) {
      list.add(_PetalSpec(
        path: _createRealisticPetalPath(48, 86),
        veinPath: _createPetalVeinsPath(48, 86),
        pathHeight: 86.0,
        baseAngle: angle,
        startMs: 2760.0,
        durationMs: 640.0,
        shader: shader3,
      ));
    }

    return list;
  }

  /// Vẽ cánh sen chân thật với đường cong bụng mềm mại, thon dài và chóp nhọn uốn tự nhiên
  static Path _createRealisticPetalPath(double width, double height, {double tipCurvature = 0.0}) {
    final path = Path();
    path.moveTo(0, 0);
    // Cạnh trái: bắt đầu từ cuống hẹp, phình mềm mại tại bụng cánh, vuốt thon mượt về chóp
    path.cubicTo(
      -width * 0.52, -height * 0.28,
      -width * 0.58 + tipCurvature * 6, -height * 0.72,
      tipCurvature * 5, -height,
    );
    // Cạnh phải: đối xứng hữu cơ với đỉnh chóp mềm mại
    path.cubicTo(
      width * 0.58 + tipCurvature * 6, -height * 0.72,
      width * 0.52, -height * 0.28,
      0, 0,
    );
    path.close();
    return path;
  }

  /// Hệ gân cánh sen tỏa nhánh chân thật (1 gân sống chính + 4 nhánh gân tỏa mép)
  static Path _createPetalVeinsPath(double width, double height) {
    final path = Path();
    // Gân sống chính giữa
    path.moveTo(0, 0);
    path.cubicTo(-width * 0.02, -height * 0.35, width * 0.02, -height * 0.65, 0, -height * 0.88);

    // Gân nhánh tầng dưới
    path.moveTo(-width * 0.01, -height * 0.25);
    path.cubicTo(-width * 0.18, -height * 0.35, -width * 0.32, -height * 0.45, -width * 0.38, -height * 0.55);

    path.moveTo(width * 0.01, -height * 0.25);
    path.cubicTo(width * 0.18, -height * 0.35, width * 0.32, -height * 0.45, width * 0.38, -height * 0.55);

    // Gân nhánh tầng trên
    path.moveTo(-width * 0.01, -height * 0.50);
    path.cubicTo(-width * 0.16, -height * 0.60, -width * 0.26, -height * 0.68, -width * 0.32, -height * 0.76);

    path.moveTo(width * 0.01, -height * 0.50);
    path.cubicTo(width * 0.16, -height * 0.60, width * 0.26, -height * 0.68, width * 0.32, -height * 0.76);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (currentMs < 1000.0) return;

    // Đặt tâm đóa sen ở vị trí 33% chiều cao màn hình
    final lotusCenter = Offset(size.width / 2, size.height * 0.33);
    canvas.save();
    canvas.translate(lotusCenter.dx, lotusCenter.dy);

    // =========================================================================
    // GIAI ĐOẠN 2: MẦM SEN MỌC DÀI TỪ MẶT NƯỚC (y=130) LÊN ĐỈNH (y=0)
    // =========================================================================
    double springVal = 0.0;
    if (currentMs >= 1000.0 && currentMs <= 2000.0) {
      final timeSec = (currentMs - 1000.0) / 1000.0 * 0.85;
      springVal = stemSpring.x(timeSec).clamp(0.0, 1.08);
    } else if (currentMs > 2000.0) {
      springVal = 1.0;
    }

    final currentStemLength =
        (_stemTotalLength * springVal.clamp(0.0, 1.0)).clamp(0.0, _stemTotalLength);
    Offset budTipPos = const Offset(0, 130);
    double budAngle = 0.0;

    // Trích xuất đoạn cuống sen đang sinh trưởng vươn lên từ mặt nước
    if (currentStemLength > 0.0 && _stemMetrics.isNotEmpty) {
      final m = _stemMetrics.first;
      final extractedStem = m.extractPath(0.0, currentStemLength);
      _stemPaint.color = AppColors.primary.withOpacity((springVal * 0.85).clamp(0.0, 1.0));
      canvas.drawPath(extractedStem, _stemPaint);

      final tangent = m.getTangentForOffset(currentStemLength);
      if (tangent != null) {
        budTipPos = tangent.position;
        budAngle = tangent.angle + math.pi / 2;
      }
    }

    // =========================================================================
    // GIAI ĐOẠN 3: BÚP SEN HÉ NỤ, TÁCH LÁ ĐÀI (1900 - 2400ms)
    // VÀ GIAI ĐOẠN 4: NỞ BUNG 20 CÁNH & 20 NHỤY SEN (2400 - 3400ms)
    // =========================================================================
    if (currentMs < 2400.0) {
      // Khi đang vươn lên (1000-2000ms) và hé mở nụ (1900-2400ms)
      // Hai lá đài ngoài từ từ tách hé mở ra hai bên từ 1900ms đến 2400ms
      final sepalOpenP = ((currentMs - 1900.0) / 500.0).clamp(0.0, 1.0);
      final sepalAngle = 0.32 * Curves.easeInOutCubic.transform(sepalOpenP);

      canvas.save();
      canvas.translate(budTipPos.dx, budTipPos.dy);
      canvas.rotate(budAngle);

      // Búp sen non lớn dần từ 35% kích thước mầm lên 100% khi vươn tới đỉnh
      final budScale = (0.35 + 0.65 * springVal.clamp(0.0, 1.0)) * (1.0 + 0.08 * sepalOpenP);
      canvas.scale(budScale, budScale);

      // Thân búp trắng ngọc bên trong hé lộ
      canvas.drawPath(_closedBudPath, _budPetalPaint);

      // Lá đài trái ngả mở tự nhiên
      canvas.save();
      canvas.rotate(-sepalAngle);
      canvas.drawPath(_leftSepalPath, _sepalPaint);
      canvas.restore();

      // Lá đài phải ngả mở tự nhiên
      canvas.save();
      canvas.rotate(sepalAngle);
      canvas.drawPath(_rightSepalPath, _sepalPaint);
      canvas.restore();

      canvas.restore();
    } else {
      // Từ 2400ms trở đi: Vẽ cả thân cuống sen đầy đủ đứng vững chãi
      _stemPaint.color = AppColors.primary.withOpacity(0.85);
      canvas.drawPath(_stemPath, _stemPaint);

      // 20 cánh hoa nở bung 4 tầng hữu cơ đều đặn 360 độ quanh tâm (0, 0)
      for (final petal in _petals) {
        if (currentMs < petal.startMs) continue;

        final p = ((currentMs - petal.startMs) / petal.durationMs).clamp(0.0, 1.0);
        // Curves.easeOutBack mang lại hiệu ứng overshoot nhẹ khi nở và xoay 3-5 độ (~0.065 rad = 3.72 độ)
        final curvedP = Curves.easeOutBack.transform(p);

        final currentScale = curvedP;
        // Xoay chuẩn 3-5 độ từ tư thế búp hé bung xòe ra vị trí xòe trọn vẹn
        final rotationOffset = (petal.baseAngle == 0.0 ? 0.0 : (petal.baseAngle > 0 ? 1.0 : -1.0)) *
            (0.065 * (1.0 - curvedP));
        final currentAngle = petal.baseAngle - rotationOffset;

        _petalFillPaint.shader = petal.shader;

        canvas.save();
        canvas.rotate(currentAngle);
        canvas.scale(currentScale, currentScale);

        // 1. Thân cánh sen với gradient
        canvas.drawPath(petal.path, _petalFillPaint);

        // 2. Viền cánh sen sắc nét mờ nhẹ
        canvas.drawPath(petal.path, _petalBorderPaint);

        // 3. Hệ gân cánh sen hữu cơ chân thật
        canvas.drawPath(petal.veinPath, _petalVeinPaint);

        canvas.restore();
      }

      // =======================================================================
      // ĐÀI GƯƠNG SEN & 20 TUA NHỤY NGỌC BUNG TỎA (2760 - 3400ms)
      // =======================================================================
      final coreBloomP = ((currentMs - 2760.0) / 640.0).clamp(0.0, 1.0);
      if (coreBloomP > 0.0) {
        final easedP = Curves.easeOutCubic.transform(coreBloomP);
        final coreRadius = 17.0 * easedP;

        // Quầng hào quang ngọc lam tâm hoa
        _coreGlowPaint.color = AppColors.bottomBarGlow.withOpacity(0.55 * coreBloomP);
        canvas.drawCircle(Offset.zero, coreRadius * 2.4, _coreGlowPaint);

        // Vòng 20 tua nhị đực tỏa tròn 360 độ (Stamen filaments)
        _filamentPaint.color = AppColors.primaryLight.withOpacity(0.88 * coreBloomP);
        const int numFilaments = 20;
        for (int i = 0; i < numFilaments; i++) {
          final angle = (i * 2 * math.pi / numFilaments);
          final innerR = coreRadius * 0.40;
          // Nhị sen xòe dài và uốn cong nhẹ ra ngoài
          final outerR = coreRadius * (1.30 + 0.15 * math.sin(i * 1.5));
          final start = Offset(math.cos(angle) * innerR, math.sin(angle) * innerR);
          final end = Offset(math.cos(angle) * outerR, math.sin(angle) * outerR);
          canvas.drawLine(start, end, _filamentPaint);

          // Bao phấn sen (Anther) hình hạt gạo phát sáng ở đầu mỗi sợi nhị
          final antherAngle = angle + math.pi / 2;
          canvas.save();
          canvas.translate(end.dx, end.dy);
          canvas.rotate(antherAngle);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 3.2 * easedP, height: 1.6 * easedP),
            _antherPaint,
          );
          canvas.restore();
        }

        // Gương sen trung tâm (Receptacle disc)
        canvas.drawCircle(Offset.zero, coreRadius, _corePaint);
        canvas.drawCircle(Offset.zero, coreRadius, _coreRimPaint);

        // 9 mắt sen đối xứng tự nhiên (seed pits)
        _seedSpotPaint.color = AppColors.primary.withOpacity(0.75 * coreBloomP);
        // Mắt sen trung tâm
        canvas.drawCircle(Offset.zero, 2.0 * easedP, _seedSpotPaint);
        // 8 mắt sen vòng quanh
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4.0;
          final spotPos = Offset(math.cos(angle) * coreRadius * 0.52, math.sin(angle) * coreRadius * 0.52);
          canvas.drawCircle(spotPos, 1.5 * easedP, _seedSpotPaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LotusBloomPainter oldDelegate) {
    final isActive = currentMs >= 1000.0 && currentMs <= 3400.0;
    final wasActive = oldDelegate.currentMs >= 1000.0 && oldDelegate.currentMs <= 3400.0;
    return isActive || wasActive;
  }
}

class _PetalSpec {
  final Path path;
  final Path veinPath;
  final double pathHeight;
  final double baseAngle;
  final double startMs;
  final double durationMs;
  final Shader shader;

  _PetalSpec({
    required this.path,
    required this.veinPath,
    required this.pathHeight,
    required this.baseAngle,
    required this.startMs,
    required this.durationMs,
    required this.shader,
  });
}
