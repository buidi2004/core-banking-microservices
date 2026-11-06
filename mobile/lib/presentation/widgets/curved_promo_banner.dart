import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Dữ liệu mẫu cho các banner quảng cáo thời trang & phong cách sống chân thực
class _PromoData {
  final String badgeText;
  final IconData badgeIcon;
  final String title;
  final String highlightValue;
  final String highlightText;
  final String buttonText;
  final List<Color> gradientColors;
  final Color shadowColor;
  final String route;
  final String imageAsset;
  final Color accentColor;

  const _PromoData({
    required this.badgeText,
    required this.badgeIcon,
    required this.title,
    required this.highlightValue,
    required this.highlightText,
    required this.buttonText,
    required this.gradientColors,
    required this.shadowColor,
    required this.route,
    required this.imageAsset,
    required this.accentColor,
  });
}

/// Banner quảng cáo có góc bo cong nghệ thuật ("Bẻ cong ảnh dưới" & "Ghép ảnh chéo")
/// Tự động chạy các quảng cáo thương hiệu thời trang & phong cách sống luân phiên
class CurvedPromoBanner extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  final bool isDiagonalSlanted;

  const CurvedPromoBanner({
    super.key,
    this.onRegisterTap,
    this.isDiagonalSlanted = false,
  });

  @override
  State<CurvedPromoBanner> createState() => _CurvedPromoBannerState();
}

class _CurvedPromoBannerState extends State<CurvedPromoBanner> {
  static const List<_PromoData> _promos = [
    // Quảng cáo 1: ZARA & UNIQLO - BST Thời trang Hè (Ảnh người thật mua sắm)
    _PromoData(
      badgeText: 'ZARA × UNIQLO',
      badgeIcon: CupertinoIcons.bag_fill,
      title: 'BST THỜI TRANG HÈ',
      highlightValue: 'GIẢM 300K',
      highlightText: 'ĐƠN TỪ 1.5TR',
      buttonText: 'SĂN DEAL NGAY',
      gradientColors: [
        Color(0xFF0F172A),
        Color(0xF01E293B),
        Color(0x99334155),
        Color(0x000F172A),
      ],
      shadowColor: Color(0xFF0F172A),
      route: '/promotions',
      imageAsset: 'assets/images/banners/banner_zara_uniqlo.jpg',
      accentColor: Color(0xFFF2B84B),
    ),

    // Quảng cáo 2: NIKE & ADIDAS - Sport Fest (Ảnh người mẫu thể thao năng động)
    _PromoData(
      badgeText: 'NIKE × ADIDAS',
      badgeIcon: CupertinoIcons.bolt_fill,
      title: 'SPORT FEST 2026',
      highlightValue: 'HOÀN 20%',
      highlightText: 'VISA PLATINUM',
      buttonText: 'MỞ THẺ NGAY',
      gradientColors: [
        Color(0xFF020C1B),
        Color(0xF00A192F),
        Color(0x88172A45),
        Color(0x000A192F),
      ],
      shadowColor: Color(0xFF0A192F),
      route: '/cards',
      imageAsset: 'assets/images/banners/banner_nike_adidas.jpg',
      accentColor: Color(0xFFFF6B5F),
    ),

    // Quảng cáo 3: GUCCI & CHANEL - Luxury Runway Boutique (Ảnh người mẫu thời trang cao cấp)
    _PromoData(
      badgeText: 'GUCCI × CHANEL',
      badgeIcon: CupertinoIcons.star_fill,
      title: 'LUXURY BOUTIQUE',
      highlightValue: 'HOÀN 10%',
      highlightText: 'ĐẶC QUYỀN VIP',
      buttonText: 'KHÁM PHÁ NGAY',
      gradientColors: [
        Color(0xFF1A120B),
        Color(0xF0271E18),
        Color(0x883E2723),
        Color(0x001A120B),
      ],
      shadowColor: Color(0xFF271E18),
      route: '/cards',
      imageAsset: 'assets/images/banners/banner_gucci_luxury.jpg',
      accentColor: Color(0xFFE8C98A),
    ),

    // Quảng cáo 4: GENTLE MONSTER & RESORT - Du lịch & Nghỉ dưỡng
    _PromoData(
      badgeText: 'GENTLE MONSTER',
      badgeIcon: CupertinoIcons.sun_max_fill,
      title: 'DU LỊCH & RESORT',
      highlightValue: 'TẶNG 1TR',
      highlightText: 'VOUCHER 5 SAO',
      buttonText: 'NHẬN ƯU ĐÃI',
      gradientColors: [
        Color(0xFF00222C),
        Color(0xF0003847),
        Color(0x88005A6F),
        Color(0x0000222C),
      ],
      shadowColor: Color(0xFF003847),
      route: '/promotions',
      imageAsset: 'assets/images/banners/banner_travel_resort.jpg',
      accentColor: Color(0xFF54D6C8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isDiagonalSlanted) {
      return _buildDiagonalSlantedBanner(context);
    }
    return _buildAutoRunningBanner(context);
  }

  Widget _buildAutoRunningBanner(BuildContext context) {
    return FlutterCarousel.builder(
      itemCount: _promos.length,
      itemBuilder: (context, index, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildSinglePromoCard(context, _promos[index]),
        );
      },
      height: 164,
      viewportFraction: 0.86,
      infinite: true,
      padEnds: true,
      effect: const CarouselEffect.enlarge(factor: 0.08),
      indicator: const CarouselIndicator(
        painter: CircularSlideIndicator(
          style: SlideIndicatorStyle(
            activeColor: Colors.white,
            inactiveColor: Color(0x66FFFFFF),
            radius: 3,
            spacing: 8,
            animated: true,
          ),
        ),
        placement: CarouselIndicatorPlacement.overlay,
        alignment: Alignment.bottomRight,
        margin: EdgeInsets.fromLTRB(0, 0, 14, 10),
      ),
      autoPlay: const CarouselAutoPlay(
        interval: Duration(seconds: 4),
        duration: Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      ),
      edgeAlignment: CarouselEdgeAlignment.center,
    );
  }

  Widget _buildSinglePromoCard(BuildContext context, _PromoData promo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 164,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: promo.shadowColor.withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Ảnh người thật và thương hiệu thời trang chất lượng cao
            Positioned.fill(
              child: Image.asset(
                promo.imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),

            // 2. Lớp gradient cinematic chuyển màu tinh tế để bảo toàn độ tương phản văn bản
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      promo.gradientColors[0],
                      promo.gradientColors[1],
                      promo.gradientColors[2],
                      promo.gradientColors[3],
                    ],
                    stops: const [0.0, 0.48, 0.74, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Ánh sáng màu nhẹ để ảnh và chữ hòa vào cùng hệ thương hiệu.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      promo.accentColor.withOpacity(0.12),
                      Colors.transparent,
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Nội dung chính bên trái
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tag huy hiệu thương hiệu thời trang
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.40),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(promo.badgeIcon,
                                  color: AppColors.bottomBarCyan, size: 10),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  promo.badgeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Tiêu đề chương trình ưu đãi
                        Text(
                          promo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.55),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Dòng phụ: Huy hiệu nổi bật
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.bottomBarCyan,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                promo.highlightValue,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                promo.highlightText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        // Nút hành động (SĂN DEAL NGAY, MỞ THẺ NGAY...)
                        InkWell(
                          onTap: () {
                            if (widget.onRegisterTap != null) {
                              widget.onRegisterTap!();
                            } else {
                              context.push(promo.route);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      promo.buttonText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    CupertinoIcons.arrow_right,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Khoảng đệm bên phải (flex 5) để ảnh người thật thời trang hiển thị tự nhiên
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bố cục Ghép ảnh chéo (Diagonal Slanted Composite Banner)
  /// Khớp chính xác góc nghiêng, dải màu teal-yellow và ảnh ghép chéo người thật du lịch
  Widget _buildDiagonalSlantedBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF003847),
              Color(0xFF004F60),
              Color(0xFF00667C),
              Color(0xFF007A94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A9396).withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Dải sóng chéo nền (Diagonal Wave Streaks)
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalWaveBackgroundPainter(),
              ),
            ),

            // 2. ẢNH GHÉP CHÉO BÊN PHẢI (Diagonal Photo Card - Người thật du lịch nghỉ dưỡng)
            Positioned(
              right: -10,
              top: -8,
              bottom: -12,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(-2, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/banners/slanted_travel_photo.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        // Gradient mờ ở đáy ảnh
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 38,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.75),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Huy hiệu tag du lịch hè
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DU LỊCH HÈ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brandBlue,
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

            // 3. NỘI DUNG CHÉO BÊN TRÁI (Slanted Typography & Yellow 100K Badge)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 85, 10),
              child: Transform.rotate(
                angle: -0.05,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge nhỏ trên đỉnh
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 0.7,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.gift_fill,
                              color: AppColors.bottomBarCyan, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'ƯU ĐÃI ĐẶC QUYỀN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Tiêu đề: GÓI TIẾT KIỆM (chữ trắng 3D nghiêng chéo)
                    Text(
                      'GÓI TIẾT KIỆM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.40),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Dòng huy hiệu vàng: 100K ƯU ĐÃI (nổi bật rực rỡ)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.bottomBarOcean.withOpacity(0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: const Text(
                            '100K',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'ƯU ĐÃI',
                            style: TextStyle(
                              color: Color(0xFFFFEB3B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Nút ĐĂNG KÝ NGAY
                    InkWell(
                      onTap: widget.onRegisterTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ĐĂNG KÝ NGAY',
                              style: TextStyle(
                                color: AppColors.brandBlue,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              CupertinoIcons.arrow_right,
                              size: 9.5,
                              color: AppColors.brandBlue,
                            ),
                          ],
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
    );
  }
}

/// CustomPainter vẽ các dải sóng và vệt sáng chéo cho banner ghép ảnh chéo
class _DiagonalWaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dải sóng chéo ngọc lam đậm
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.lineTo(size.width * 0.85, 0);
    path1.lineTo(size.width, 0);
    path1.lineTo(size.width, size.height * 0.7);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // 2. Vệt sáng chéo trắng mờ
    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.25, size.height);
    path2.lineTo(size.width * 0.95, size.height * 0.25);
    path2.lineTo(size.width, size.height * 0.35);
    path2.lineTo(size.width * 0.45, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // 3. Vòng tròn trang trí góc trái đáy
    final circlePaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.85), 55, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
