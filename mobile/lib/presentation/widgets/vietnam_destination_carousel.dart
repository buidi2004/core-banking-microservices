import 'dart:async';

import 'package:flutter/material.dart';

/// A small editorial carousel featuring real Vietnamese destinations already
/// included in the app's local image assets.
class VietnamDestinationCarousel extends StatefulWidget {
  const VietnamDestinationCarousel({super.key});

  @override
  State<VietnamDestinationCarousel> createState() =>
      _VietnamDestinationCarouselState();
}

class _VietnamDestinationCarouselState
    extends State<VietnamDestinationCarousel> {
  static const _destinations = [
    (
      image: 'assets/images/banners/halong_bay.webp',
      name: 'Vịnh Hạ Long',
      detail: 'Di sản thiên nhiên thế giới · Quảng Ninh',
      credit: null,
    ),
    (
      image: 'assets/images/banners/trang_an.webp',
      name: 'Quần thể Tràng An',
      detail: 'Di sản hỗn hợp thế giới · Ninh Bình',
      credit: null,
    ),
    (
      image: 'assets/images/banners/da_nang_golden_bridge.webp',
      name: 'Cầu Vàng, Bà Nà Hills',
      detail: 'Đà Nẵng · Cây cầu giữa mây trời',
      credit: null,
    ),
    (
      image: 'assets/images/banners/phu_quoc.webp',
      name: 'Đảo Ngọc Phú Quốc',
      detail: 'Kiên Giang · Biển xanh phương Nam',
      credit: null,
    ),
    (
      image: 'assets/images/banners/hoi_an_people.webp',
      name: 'Phố cổ Hội An',
      detail: 'Di sản văn hóa · Nhịp sống bên sông Hoài',
      credit: 'Ảnh: Mark Fischer · CC BY-SA 2.0',
    ),
    (
      image: 'assets/images/banners/sapa_terraces.webp',
      name: 'Ruộng bậc thang Sa Pa',
      detail: 'Lào Cai · Những thửa ruộng theo sườn núi',
      credit: 'Ảnh: Konstantin Krismer · CC BY 3.0',
    ),
    (
      image: 'assets/images/banners/hue_meridian_gate.webp',
      name: 'Ngọ Môn, Hoàng thành Huế',
      detail: 'Quần thể di tích Cố đô Huế · Di sản UNESCO',
      credit: 'Ảnh: Vyacheslav Argenberg · CC BY 4.0',
    ),
    (
      image: 'assets/images/banners/can_tho_floating_market.webp',
      name: 'Chợ nổi Cái Răng',
      detail: 'Cần Thơ · Chợ sông buổi sớm miền Tây',
      credit: 'Ảnh: Vyacheslav Argenberg · CC BY 4.0',
    ),
  ];

  final _pageController = PageController(viewportFraction: 0.91);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final next = (_page + 1) % _destinations.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Điểm đến Việt Nam',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'ẢNH ĐỊA DANH',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 164,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _destinations.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          destination.image,
                          fit: BoxFit.cover,
                          cacheWidth: 1000,
                          cacheHeight: 620,
                          filterQuality: FilterQuality.medium,
                          semanticLabel: destination.name,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xC9000000)],
                              stops: [.35, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 14,
                                  color: Color(0xFF087E8B),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'SEN HỒNG TRAVEL',
                                  style: TextStyle(
                                    color: Color(0xFF17324D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Semantics(
                            label: 'Gợi ý ưu đãi du lịch Sen Hồng',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFC857),
                                        Color(0xFFFF7A59),
                                        Color(0xFFDE4D8A),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.95),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_activity_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'ƯU ĐÃI',
                                    style: TextStyle(
                                      color: Color(0xFF9A3F46),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                destination.detail,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 12,
                                ),
                              ),
                              if (destination.credit != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  destination.credit!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _destinations.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: index == _page ? 18 : 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _page
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
