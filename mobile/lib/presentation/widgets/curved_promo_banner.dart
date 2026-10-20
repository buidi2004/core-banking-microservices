import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dữ liệu mẫu cho 4 banner quảng cáo tự động chạy từ phải sang trái
class _PromoData {
  final String badgeText;
  final IconData badgeIcon;
  final String title;
  final String highlightValue;
  final String highlightText;
  final String buttonText;
  final Color buttonTextColor;
  final IconData rightIcon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final String route;

  const _PromoData({
    required this.badgeText,
    required this.badgeIcon,
    required this.title,
    required this.highlightValue,
    required this.highlightText,
    required this.buttonText,
    required this.buttonTextColor,
    required this.rightIcon,
    required this.gradientColors,
    required this.shadowColor,
    required this.route,
  });
}

/// Banner quảng cáo có góc bo cong nghệ thuật ("Bẻ cong ảnh dưới" & "Ghép ảnh chéo")
/// Tự động chạy 4 quảng cáo luân phiên từ phải sang trái với bố cục giữ nguyên tuyệt đối
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
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  // ValueNotifier để chỉ rebuild dots indicator, không rebuild toàn banner
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  static const int _virtualInitialPage = 4000;

  static const List<_PromoData> _promos = [
    // Quảng cáo 1: Gói Tiết Kiệm (Banner gốc chuẩn mẫu)
    _PromoData(
      badgeText: 'ƯU ĐÃI ĐẶC QUYỀN',
      badgeIcon: CupertinoIcons.sparkles,
      title: 'GÓI TIẾT KIỆM',
      highlightValue: '100K',
      highlightText: 'ƯU ĐÃI',
      buttonText: 'ĐĂNG KÝ NGAY',
      buttonTextColor: Color(0xFF0077B6),
      rightIcon: CupertinoIcons.money_dollar_circle_fill,
      gradientColors: [
        Color(0xFF005C8A),
        Color(0xFF0083B0),
        Color(0xFF00B4DB),
        Color(0xFF48CAE4),
      ],
      shadowColor: Color(0xFF0083B0),
      route: '/bills/savings',
    ),

    // Quảng cáo 2: Thẻ Tín Dụng SenBank Visa Platinum (Hoàn tiền)
    _PromoData(
      badgeText: 'HOÀN TIỀN CỰC ĐỈNH',
      badgeIcon: CupertinoIcons.star_fill,
      title: 'THẺ SEN PLATINUM',
      highlightValue: '50%',
      highlightText: 'HOÀN TIỀN',
      buttonText: 'MỞ THẺ NGAY',
      buttonTextColor: Color(0xFF7B1FA2),
      rightIcon: CupertinoIcons.creditcard_fill,
      gradientColors: [
        Color(0xFF4A0E4E),
        Color(0xFF6A1B9A),
        Color(0xFF8E24AA),
        Color(0xFFAB47BC),
      ],
      shadowColor: Color(0xFF6A1B9A),
      route: '/cards',
    ),

    // Quảng cáo 3: Vay Tiêu Dùng Siêu Tốc (0% lãi suất)
    _PromoData(
      badgeText: 'GIẢI NGÂN 15 PHÚT',
      badgeIcon: CupertinoIcons.rocket_fill,
      title: 'VAY SIÊU TỐC',
      highlightValue: '0%',
      highlightText: 'LÃI THÁNG ĐẦU',
      buttonText: 'NHẬN TIỀN NGAY',
      buttonTextColor: Color(0xFF00695C),
      rightIcon: CupertinoIcons.money_dollar_circle_fill,
      gradientColors: [
        Color(0xFF004D40),
        Color(0xFF00695C),
        Color(0xFF00897B),
        Color(0xFF26A69A),
      ],
      shadowColor: Color(0xFF00695C),
      route: '/bills/quick-loan',
    ),

    // Quảng cáo 4: Bảo Hiểm Toàn Diện SenCare
    _PromoData(
      badgeText: 'BẢO VỆ TOÀN DIỆN',
      badgeIcon: CupertinoIcons.shield_fill,
      title: 'BẢO HIỂM SENCARE',
      highlightValue: '1 TỶ',
      highlightText: 'BẢO VỆ GIA ĐÌNH',
      buttonText: 'KHÁM PHÁ NGAY',
      buttonTextColor: Color(0xFF0077B6),
      rightIcon: CupertinoIcons.shield_lefthalf_fill,
      gradientColors: [
        Color(0xFF0B192C),
        Color(0xFF1E3E62),
        Color(0xFF008DDA),
        Color(0xFF41C9E2),
      ],
      shadowColor: Color(0xFF1E3E62),
      route: '/promotions',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isDiagonalSlanted) {
      _pageController = PageController(initialPage: _virtualInitialPage);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3, milliseconds: 500), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _currentPageNotifier.dispose();
    if (!widget.isDiagonalSlanted) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDiagonalSlanted) {
      return _buildDiagonalSlantedBanner(context);
    }
    return _buildAutoRunningBanner(context);
  }

  Widget _buildAutoRunningBanner(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _autoScrollTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _startAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Chỉ cập nhật notifier — không rebuild toàn banner
                _currentPageNotifier.value = index % _promos.length;
              },
              itemBuilder: (context, virtualIndex) {
                final promo = _promos[virtualIndex % _promos.length];
                return _buildSinglePromoCard(context, promo);
              },
            ),
          ),

          // 4 Chấm chỉ báo trang — chỉ phần này rebuild khi đổi trang
          Positioned(
            bottom: 12,
            right: 22,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentIndex, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_promos.length, (i) {
                    final isSelected = i == currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isSelected ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.38),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePromoCard(BuildContext context, _PromoData promo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: promo.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: promo.shadowColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lớp đồ họa lượn sóng bo cong nghệ thuật ở nền dưới ("bẻ cong ảnh dưới")
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvedWaveBackgroundPainter(),
              ),
            ),

            // Các hạt lấp lánh & vòng tròn trang trí
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: 40,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F).withOpacity(0.15),
                ),
              ),
            ),

            // Nội dung chính (Giữ nguyên chính xác bố cục theo mẫu tham chiếu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tag huy hiệu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(promo.badgeIcon, color: const Color(0xFF26E5DC), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                promo.badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tiêu đề chữ trắng 3D
                        Text(
                          promo.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        // Dòng phụ: Huy hiệu vàng nổi 3D
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                promo.highlightValue,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              promo.highlightText,
                              style: const TextStyle(
                                color: Color(0xFFFFEB3B),
                                fontSize: 16,
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
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Nút hành động (ĐĂNG KÝ NGAY, MỞ THẺ NGAY...)
                        InkWell(
                          onTap: () {
                            if (widget.onRegisterTap != null) {
                              widget.onRegisterTap!();
                            } else {
                              context.push(promo.route);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  promo.buttonText,
                                  style: TextStyle(
                                    color: promo.buttonTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.arrow_right,
                                  size: 12,
                                  color: promo.buttonTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Đồ họa icon 3D bên phải với vầng hào quang
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Hào quang tỏa sáng
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                        // Biểu tượng 3D ngân hàng
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            promo.rightIcon,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bố cục Ghép ảnh chéo (Diagonal Slanted Composite Banner)
  /// Khớp chính xác góc nghiêng, dải màu teal-yellow và ảnh ghép chéo trong ảnh mẫu tham chiếu
  Widget _buildDiagonalSlantedBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 195,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF005F73),
              Color(0xFF0A9396),
              Color(0xFF0096C7),
              Color(0xFF48CAE4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A9396).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
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

            // 2. ẢNH GHÉP CHÉO BÊN PHẢI (Diagonal Photo Card)
            // Khung ảnh bo cong nghiêng chéo góc -10 độ thể hiện du lịch/tận hưởng cuộc sống
            Positioned(
              right: -15,
              top: -10,
              bottom: -15,
              child: Transform.rotate(
                angle: -0.20, // Nghiêng chéo ~11.5 độ (tăng thêm 1 xíu từ -0.16)
                child: Container(
                  width: 155,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE0F7FA),
                        Color(0xFF80DEEA),
                        Color(0xFF00ACC1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(28), // Bo cong viền ảnh từ 24px lên 28px
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 16,
                        offset: const Offset(-3, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vòng cung mặt nước / bầu trời
                      Positioned(
                        top: 20,
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                      // Icon du lịch / thuyền buồm / trải nghiệm
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.compass_fill,
                            size: 44,
                            color: const Color(0xFF0077B6).withOpacity(0.90),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'DU LỊCH HÈ',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. NỘI DUNG CHÉO BÊN TRÁI (Slanted Typography & Yellow 100K Badge)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 140, 16),
              child: Transform.rotate(
                angle: -0.06, // Nghiêng nhẹ đồng điệu theo ảnh mẫu
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge nhỏ trên đỉnh
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.gift_fill, color: Color(0xFF26E5DC), size: 13),
                          SizedBox(width: 4),
                          Text(
                            'ƯU ĐÃI ĐẶC QUYỀN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tiêu đề: GÓI TIẾT KIỆM (chữ trắng 3D nghiêng chéo)
                    Text(
                      'GÓI TIẾT KIỆM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.40),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Dòng huy hiệu vàng: 100K ƯU ĐÃI (nổi bật rực rỡ)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            '100K',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ƯU ĐÃI',
                          style: TextStyle(
                            color: Color(0xFFFFEB3B),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Nút ĐĂNG KÝ NGAY
                    InkWell(
                      onTap: widget.onRegisterTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ĐĂNG KÝ NGAY',
                              style: TextStyle(
                                color: Color(0xFF0077B6),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.arrow_right,
                              size: 12,
                              color: Color(0xFF0077B6),
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


/// CustomPainter vẽ đường cong sóng biển uốn lượn ở góc dưới của banner ("bẻ cong ảnh dưới")
class _CurvedWaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sóng phụ mờ 1
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.45);
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.2,
      size.width * 0.7,
      size.height * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.65,
      size.width,
      size.height * 0.4,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Sóng chính uốn cong đáy 2
    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.3,
      size.height * 0.45,
      size.width * 0.6,
      size.height * 0.85,
      size.width,
      size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 55, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

