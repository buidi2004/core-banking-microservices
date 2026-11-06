import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class PromotionCategoryScreen extends StatefulWidget {
  const PromotionCategoryScreen({
    required this.categoryKey,
    this.promotions = const [],
    this.flashDeals = const [],
    this.installmentDeals = const [],
    this.events = const [],
    super.key,
  });

  final String categoryKey;
  final List<Map<String, dynamic>> promotions;
  final List<Map<String, dynamic>> flashDeals;
  final List<Map<String, dynamic>> installmentDeals;
  final List<Map<String, dynamic>> events;

  @override
  State<PromotionCategoryScreen> createState() =>
      _PromotionCategoryScreenState();
}

class _PromotionCategoryScreenState extends State<PromotionCategoryScreen> {
  final _pageController = PageController(viewportFraction: .93);
  Timer? _timer;
  int _page = 0;

  static const _themes = <String, _PromotionTheme>{
    'car': _PromotionTheme(
      key: 'car',
      title: 'Vay xe 0%',
      eyebrow: 'LĂN BÁNH THEO CÁCH CỦA BẠN',
      intro: 'Chọn mẫu xe, xem ưu đãi vay và phương án trả góp phù hợp.',
      accent: Color(0xFF0878A5),
      icon: Icons.directions_car_filled_outlined,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/banner_car_couple_raw.jpg',
          title: 'Cùng nhau đi xa hơn',
          detail: 'Ưu đãi vay xe dành cho những hành trình mới',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/banner_car_driver_raw.jpg',
          title: 'Chủ động tay lái',
          detail: 'Xem gói vay xe điện và xe gia đình',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/banner_car_loan_couple.png',
          title: 'Ưu đãi vay xe',
          detail: 'Thông tin khoản vay và điều kiện áp dụng',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Ô tô điện VF3 · VF5 · VF8',
          detail: 'Gói vay xe điện, hỗ trợ tối đa 85% giá trị xe.',
          badge: 'Ô TÔ ĐIỆN',
          image: 'assets/images/banners/banner_car_loan_couple.png',
          icon: Icons.directions_car_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Xem gói vay',
        ),
        _CatalogItem(
          title: 'Feliz S · Evo200',
          detail: 'Gói trả góp xe máy điện, tham khảo từ 390.000đ/tháng.',
          badge: 'XE MÁY ĐIỆN',
          image: 'assets/images/banners/banner_car_driver_raw.jpg',
          icon: Icons.electric_moped_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Xem gói vay',
        ),
        _CatalogItem(
          title: 'Ô tô gia đình',
          detail: 'Xem phương án trả góp và kỳ hạn vay theo hồ sơ.',
          badge: 'TƯ VẤN VAY',
          image: 'assets/images/banners/banner_car_couple_raw.jpg',
          icon: Icons.family_restroom_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Tìm hiểu',
        ),
      ],
    ),
    'home': _PromotionTheme(
      key: 'home',
      title: 'Ưu đãi mua nhà',
      eyebrow: 'AN CƯ DÀI LÂU',
      intro:
          'Khám phá các gói vay nhà ở cùng hình ảnh khu đô thị tại Việt Nam.',
      accent: Color(0xFF537A68),
      icon: Icons.home_work_outlined,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/mizuki_residence.webp',
          title: 'Mizuki Park',
          detail: 'Khu đô thị Nam Sài Gòn',
          credit: 'Ảnh: Khudothi · CC BY-SA 4.0',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/lavita_residence.webp',
          title: 'Lavita Charm',
          detail: 'Không gian sống tại TP. Thủ Đức',
          credit: 'Ảnh: Trieudu · CC BY-SA 4.0',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Căn hộ & chung cư',
          detail: 'Gói vay nhà ở hiện có: thời hạn đến 35 năm.',
          badge: 'AN CƯ',
          image: 'assets/images/banners/mizuki_residence.webp',
          icon: Icons.apartment_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Xem gói vay',
        ),
        _CatalogItem(
          title: 'Nhà phố',
          detail: 'Tìm hiểu hạn mức và phương án trả góp phù hợp.',
          badge: 'NHÀ Ở',
          image: 'assets/images/banners/lavita_residence.webp',
          icon: Icons.home_work_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Tìm hiểu',
        ),
        _CatalogItem(
          title: 'Dự án đối tác',
          detail: 'Vinhomes, Masterise và Novaland được nêu trong gói vay.',
          badge: 'ĐỐI TÁC',
          image: 'assets/images/banners/mizuki_residence.webp',
          icon: Icons.location_city_outlined,
          route: '/bills/quick-loan',
          actionLabel: 'Xem gói vay',
        ),
      ],
    ),
    'electronics': _PromotionTheme(
      key: 'electronics',
      title: 'Điện máy & Công nghệ',
      eyebrow: 'NÂNG CẤP GÓC SỐNG SỐ',
      intro: 'Ưu đãi trả góp cho điện thoại, máy tính và thiết bị gia đình.',
      accent: Color(0xFF1976A8),
      icon: Icons.devices_other_outlined,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/tech_at_home.webp',
          title: 'Công nghệ trong tầm tay',
          detail: 'Xem ưu đãi điện máy và thiết bị cá nhân',
          credit: 'Ảnh: Shixart1985 · CC BY 2.0',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/laptop_product.webp',
          title: 'Thiết bị cho công việc',
          detail: 'Laptop và sản phẩm công nghệ',
          credit: 'Ảnh thuộc phạm vi công cộng · Wikimedia Commons',
        ),
        _PromotionSlide(
          image: 'assets/images/service-icons/promo_3d_phone.png',
          title: 'Trả góp thiết bị',
          detail: 'Xem kỳ hạn và điều kiện của từng ưu đãi',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Điện thoại',
          detail: 'Tham khảo gói trả góp điện thoại qua thẻ SenBank.',
          badge: 'SMARTPHONE',
          image: 'assets/images/service-icons/promo_3d_phone.png',
          icon: Icons.smartphone,
          route: '/cards',
          actionLabel: 'Xem thẻ',
        ),
        _CatalogItem(
          title: 'Laptop & MacBook',
          detail: 'Gói điện máy có nhắc MacBook Air M3 và laptop gaming.',
          badge: 'MÁY TÍNH',
          image: 'assets/images/banners/laptop_product.webp',
          icon: Icons.laptop_mac_outlined,
          route: '/cards',
          actionLabel: 'Xem thẻ',
        ),
        _CatalogItem(
          title: 'TV Sony OLED',
          detail: 'Thiết bị giải trí gia đình trong danh mục trả góp điện máy.',
          badge: 'TV',
          image: 'assets/images/banners/tech_at_home.webp',
          icon: Icons.tv_outlined,
          route: '/cards',
          actionLabel: 'Xem thẻ',
        ),
        _CatalogItem(
          title: 'Tủ lạnh Samsung Bespoke',
          detail: 'Xem điều kiện chuyển đổi trả góp tại đối tác bán lẻ.',
          badge: 'ĐIỆN GIA DỤNG',
          image: 'assets/images/banners/tech_at_home.webp',
          icon: Icons.kitchen_outlined,
          route: '/cards',
          actionLabel: 'Xem thẻ',
        ),
      ],
    ),
    'highlands': _PromotionTheme(
      key: 'highlands',
      title: 'Highlands Coffee',
      eyebrow: 'HẸN NHAU BÊN LY CÀ PHÊ',
      intro:
          'Ưu đãi đồ uống và bánh từ Highlands Coffee trong danh sách SenBank.',
      accent: Color(0xFF8A3F2D),
      icon: Icons.local_cafe_outlined,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/highlands_drip.webp',
          title: 'Cà phê phin Việt Nam',
          detail: 'Ảnh chụp tại Highlands Coffee, Đà Nẵng',
          credit: 'Ảnh: Dragfyre · CC BY-SA 3.0',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/rome_coffee_bar.webp',
          title: 'Từ quầy pha đến tách cà phê',
          detail: 'Một góc quán cà phê tại Rome',
          credit: 'Ảnh: Wilfredor · CC0 1.0',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Cà phê phin',
          detail: 'Khám phá thức uống cà phê truyền thống của Highlands.',
          badge: 'CÀ PHÊ',
          image: 'assets/images/banners/highlands_drip.webp',
          icon: Icons.coffee_outlined,
          route: '/scan-qr',
          actionLabel: 'Thanh toán QR',
        ),
        _CatalogItem(
          title: 'Freeze',
          detail: 'Freeze nằm trong chương trình giờ vàng của cửa hàng.',
          badge: 'GIỜ VÀNG',
          image: 'assets/images/banners/highlands_drip.webp',
          icon: Icons.ac_unit_outlined,
          route: '/scan-qr',
          actionLabel: 'Thanh toán QR',
        ),
        _CatalogItem(
          title: 'Trà Sen Vàng',
          detail: 'Sản phẩm có trong ưu đãi Highlands đang hiển thị.',
          badge: 'GIỜ VÀNG',
          image: 'assets/images/banners/rome_coffee_bar.webp',
          icon: Icons.local_florist_outlined,
          route: '/scan-qr',
          actionLabel: 'Thanh toán QR',
        ),
        _CatalogItem(
          title: 'Bánh & món ăn nhẹ',
          detail: 'Quét VietQR SenBank khi thanh toán tại cửa hàng.',
          badge: 'TẠI QUẦY',
          image: 'assets/images/banners/highlands_drip.webp',
          icon: Icons.bakery_dining_outlined,
          route: '/scan-qr',
          actionLabel: 'Thanh toán QR',
        ),
      ],
    ),
    'travel': _PromotionTheme(
      key: 'travel',
      title: 'Vé bay & Du lịch',
      eyebrow: 'MỞ LỐI NHỮNG CHUYẾN ĐI',
      intro: 'Tìm ưu đãi vé bay và cảm hứng cho hành trình tiếp theo.',
      accent: Color(0xFF087F8C),
      icon: Icons.flight_takeoff,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/paris_from_eiffel.webp',
          title: 'Paris, nước Pháp',
          detail: 'Toàn cảnh thành phố từ tháp Eiffel',
          credit: 'Ảnh: Kalepook · CC BY 2.5',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/venice_canal.webp',
          title: 'Venice, nước Ý',
          detail: 'Đại Kênh đào và những chuyến thuyền',
          credit: 'Ảnh: Ray in Manila · CC BY 2.0',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/tokyo_tower.webp',
          title: 'Tokyo, Nhật Bản',
          detail: 'Tháp Tokyo lên đèn khi thành phố về đêm',
          credit: 'Ảnh: Douglas P Perkins · Phạm vi công cộng',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Vé bay nội địa',
          detail: 'Tìm chuyến bay và xem lựa chọn vé điện tử.',
          badge: 'VÉ BAY',
          image: 'assets/images/banners/paris_from_eiffel.webp',
          icon: Icons.flight_takeoff,
          route: '/digital-flight',
          actionLabel: 'Tìm vé',
        ),
        _CatalogItem(
          title: 'Vé bay quốc tế',
          detail: 'Tra cứu hành trình và thông tin vé trên SenBank.',
          badge: 'QUỐC TẾ',
          image: 'assets/images/banners/tokyo_tower.webp',
          icon: Icons.public,
          route: '/digital-flight',
          actionLabel: 'Tìm vé',
        ),
        _CatalogItem(
          title: 'Khách sạn & resort',
          detail: 'Mở mục thanh toán dịch vụ lưu trú.',
          badge: 'LƯU TRÚ',
          image: 'assets/images/banners/venice_canal.webp',
          icon: Icons.hotel_outlined,
          route: '/bills/input?service=Khách sạn',
          actionLabel: 'Xem dịch vụ',
        ),
        _CatalogItem(
          title: 'Điểm đến nổi bật',
          detail: 'Paris, Venice và Tokyo trong bộ ảnh du lịch.',
          badge: 'CẢM HỨNG',
          image: 'assets/images/banners/paris_from_eiffel.webp',
          icon: Icons.explore_outlined,
          route: '/digital-flight',
          actionLabel: 'Tìm chuyến đi',
        ),
      ],
    ),
    'shopee': _PromotionTheme(
      key: 'shopee',
      title: 'Ưu đãi Shopee',
      eyebrow: 'MUA SẮM THÊM NIỀM VUI',
      intro: 'Tổng hợp ưu đãi mua sắm và voucher từ các đối tác bán lẻ.',
      accent: Color(0xFFDA4B36),
      icon: Icons.shopping_bag_outlined,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/banner_zara_uniqlo.jpg',
          title: 'Thời trang mỗi ngày',
          detail: 'Khám phá ưu đãi mua sắm đang có',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/banner_nike_adidas.jpg',
          title: 'Năng lượng vận động',
          detail: 'Ưu đãi sản phẩm thể thao',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/banner_gucci_luxury.jpg',
          title: 'Chọn món đồ bạn yêu thích',
          detail: 'Thanh toán qua SenBank để xem điều kiện ưu đãi',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Thời trang',
          detail: 'Khám phá ưu đãi mua sắm và phương thức thanh toán.',
          badge: 'MUA SẮM',
          image: 'assets/images/banners/banner_zara_uniqlo.jpg',
          icon: Icons.checkroom_outlined,
          route: '/cards',
          actionLabel: 'Xem phương thức',
        ),
        _CatalogItem(
          title: 'Thể thao',
          detail: 'Xem chương trình ưu đãi cho sản phẩm thể thao.',
          badge: 'THỂ THAO',
          image: 'assets/images/banners/banner_nike_adidas.jpg',
          icon: Icons.sports_outlined,
          route: '/cards',
          actionLabel: 'Xem phương thức',
        ),
        _CatalogItem(
          title: 'Voucher Shopee Mall',
          detail: 'Mã giảm giá hiện có trong mục giờ vàng.',
          badge: 'VOUCHER',
          image: 'assets/images/service-icons/promo_3d_bag.png',
          icon: Icons.local_offer_outlined,
          route: '/cards',
          actionLabel: 'Xem voucher',
        ),
        _CatalogItem(
          title: 'Sản phẩm lifestyle',
          detail: 'Tham khảo các ưu đãi bán lẻ và điều kiện thanh toán.',
          badge: 'LIFESTYLE',
          image: 'assets/images/banners/banner_gucci_luxury.jpg',
          icon: Icons.storefront_outlined,
          route: '/cards',
          actionLabel: 'Xem phương thức',
        ),
      ],
    ),
    'cashback': _PromotionTheme(
      key: 'cashback',
      title: 'Thẻ hoàn tiền',
      eyebrow: 'CHI TIÊU CÓ THÊM GIÁ TRỊ',
      intro: 'Xem chương trình hoàn tiền và quyền lợi theo từng dòng thẻ.',
      accent: Color(0xFF345C9B),
      icon: Icons.credit_card_outlined,
      containedSlides: true,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/real_featured_visa_exact.png',
          title: 'SenBank Visa',
          detail: 'Ưu đãi theo điều kiện chương trình',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/real_featured_jcb_exact.png',
          title: 'SenBank JCB',
          detail: 'Khám phá ưu đãi dành cho chủ thẻ',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/real_stellar_banner.png',
          title: 'Bộ sưu tập thẻ Stellar',
          detail: 'Chọn thiết kế phù hợp với bạn',
        ),
      ],
      catalog: [
        _CatalogItem(
          title: 'Visa Platinum',
          detail: 'Hoàn tiền theo điều kiện chương trình hiện hành.',
          badge: 'HOÀN TIỀN',
          image: 'assets/images/banners/real_featured_visa_exact.png',
          icon: Icons.credit_card_outlined,
          route: '/cards',
          actionLabel: 'Xem quyền lợi',
        ),
        _CatalogItem(
          title: 'JCB',
          detail: 'Xem dòng thẻ và ưu đãi đối tác liên quan.',
          badge: 'THẺ JCB',
          image: 'assets/images/banners/real_featured_jcb_exact.png',
          icon: Icons.credit_card,
          route: '/cards',
          actionLabel: 'Xem thẻ',
        ),
        _CatalogItem(
          title: 'Thẻ Stellar',
          detail: 'Khám phá bộ sưu tập thiết kế thẻ SenBank.',
          badge: 'BỘ SƯU TẬP',
          image: 'assets/images/banners/real_stellar_banner.png',
          icon: Icons.auto_awesome_outlined,
          route: '/cards',
          actionLabel: 'Chọn thẻ',
        ),
      ],
    ),
    'wheel': _PromotionTheme(
      key: 'wheel',
      title: 'Vòng quay may mắn',
      eyebrow: 'SỰ KIỆN & QUÀ TẶNG',
      intro:
          'Theo dõi sự kiện và thể lệ nhận quà đang hiển thị trong ứng dụng.',
      accent: Color(0xFFB97922),
      icon: Icons.casino_outlined,
      containedSlides: true,
      slides: [
        _PromotionSlide(
          image: 'assets/images/banners/stellar_card_goddess.png',
          title: 'Quà tặng đặc biệt',
          detail: 'Theo dõi sự kiện và điều kiện tham gia',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/stellar_card_heritage.png',
          title: 'Bộ sưu tập di sản',
          detail: 'Khám phá những phần quà theo chủ đề',
        ),
        _PromotionSlide(
          image: 'assets/images/banners/stellar_card_heart.png',
          title: 'Quà tặng SenBank',
          detail: 'Xem thể lệ trước khi tham gia',
        ),
      ],
    ),
  };

  _PromotionTheme get _theme => _themes[widget.categoryKey] ?? _themes['car']!;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_pageController.hasClients || _theme.slides.length < 2) return;
      final next = (_page + 1) % _theme.slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
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
    final theme = _theme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại ưu đãi',
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.chevron_back),
        ),
        title: Text(
          theme.title,
          style: const TextStyle(
            color: Color(0xFF13263A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _buildHero(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Icon(theme.icon, size: 18, color: theme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    theme.eyebrow,
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .45,
                    ),
                  ),
                ),
                Text(
                  '${theme.catalog.length + widget.promotions.length + widget.flashDeals.length + widget.installmentDeals.length + widget.events.length} mục liên quan',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 12),
            child: Text(
              theme.intro,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (theme.catalog.isNotEmpty) ...[
            const _SectionHeading(title: 'Sản phẩm & dịch vụ'),
            _buildCatalog(theme),
          ],
          if (widget.installmentDeals.isNotEmpty) ...[
            const _SectionHeading(title: 'Gói trả góp liên quan'),
            ...widget.installmentDeals.map(_buildInstallmentDeal),
          ],
          if (widget.promotions.isNotEmpty) ...[
            _SectionHeading(
              title: widget.categoryKey == 'wheel'
                  ? 'Ưu đãi đang diễn ra'
                  : 'Ưu đãi dành cho bạn',
            ),
            ...widget.promotions.map(_buildPromotion),
          ],
          if (widget.flashDeals.isNotEmpty) ...[
            const _SectionHeading(title: 'Ưu đãi giờ vàng'),
            ...widget.flashDeals.map(_buildFlashDeal),
          ],
          if (widget.events.isNotEmpty) ...[
            const _SectionHeading(title: 'Sự kiện & quà tặng'),
            ...widget.events.map(_buildEvent),
          ],
          if (widget.promotions.isEmpty &&
              widget.installmentDeals.isEmpty &&
              widget.events.isEmpty &&
              widget.flashDeals.isEmpty)
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildCatalog(_PromotionTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: theme.catalog.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 230,
        ),
        itemBuilder: (context, index) {
          final item = theme.catalog[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                context.push(item.route);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EAF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: SizedBox(
                        height: 76,
                        width: double.infinity,
                        child: item.image == null
                            ? ColoredBox(
                                color: theme.accent.withOpacity(.08),
                                child: Icon(item.icon, color: theme.accent),
                              )
                            : Image.asset(
                                item.image!,
                                fit: BoxFit.cover,
                                cacheWidth: 400,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: theme.accent.withOpacity(.08),
                                  child: Icon(item.icon, color: theme.accent),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF13263A),
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.actionLabel,
                          style: TextStyle(
                            color: theme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(_PromotionTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          SizedBox(
            height: theme.containedSlides ? 184 : 204,
            child: PageView.builder(
              controller: _pageController,
              itemCount: theme.slides.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final slide = theme.slides[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: theme.containedSlides
                        ? _buildContainedSlide(theme, slide)
                        : _buildPhotoSlide(theme, slide),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              theme.slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _page ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      index == _page ? theme.accent : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlide(_PromotionTheme theme, _PromotionSlide slide) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.image,
          fit: BoxFit.cover,
          cacheWidth: 1000,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: theme.accent.withOpacity(.12),
            child: Icon(theme.icon, size: 50, color: theme.accent),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xD9000000)],
              stops: [.28, 1],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: slide.credit == null ? 16 : 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                slide.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
              ),
              if (slide.credit != null) ...[
                const SizedBox(height: 3),
                Text(
                  slide.credit!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 9),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContainedSlide(_PromotionTheme theme, _PromotionSlide slide) {
    return Container(
      color: theme.key == 'wheel' ? const Color(0xFF18202B) : Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.key == 'wheel'
                        ? Colors.white
                        : const Color(0xFF13263A),
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.key == 'wheel'
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            height: 144,
            child: Image.asset(
              slide.image,
              fit: BoxFit.contain,
              cacheWidth: 500,
              errorBuilder: (_, __, ___) => Icon(
                theme.icon,
                color: theme.accent,
                size: 56,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotion(Map<String, dynamic> item) {
    final color = themeColor(item['gradient']);
    final route = item['route'] as String?;
    return _OfferSurface(
      accent: _theme.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['brand'] as String? ?? 'Ưu đãi SenBank',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _DealTag(
                text: item['discount'] as String? ?? 'ƯU ĐÃI',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['title'] as String? ?? '',
            style: const TextStyle(
              color: Color(0xFF13263A),
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item['desc'] as String? ?? '',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item['code'] ?? ''}  ·  ${item['expiry'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (route != null)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push(route);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _theme.accent,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Xem ưu đãi'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentDeal(Map<String, dynamic> deal) {
    final image = deal['image'] as String?;
    return _OfferSurface(
      accent: _theme.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                image,
                height: 126,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 900,
                cacheHeight: 360,
              ),
            ),
          if (image != null) const SizedBox(height: 12),
          Text(
            deal['title'] as String? ?? '',
            style: const TextStyle(
              color: Color(0xFF13263A),
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deal['partner'] as String? ?? '',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _DealTag(
                  text: deal['interest'] as String? ?? '',
                  color: _theme.accent),
              _DealTag(
                  text: deal['maxLimit'] as String? ?? '',
                  color: _theme.accent),
              _DealTag(
                  text: deal['duration'] as String? ?? '',
                  color: _theme.accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deal['desc'] as String? ?? '',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/bills/quick-loan');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Tìm hiểu gói vay'),
              style: TextButton.styleFrom(
                foregroundColor: _theme.accent,
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDeal(Map<String, dynamic> deal) {
    final route = deal['route'] as String?;
    return _OfferSurface(
      accent: _theme.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal['brand'] as String? ?? '',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _DealTag(
                text: deal['discount'] as String? ?? '',
                color: _theme.accent,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            (deal['title'] as String? ?? '').replaceAll('\n', ' '),
            style: const TextStyle(
              color: Color(0xFF13263A),
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${deal['code'] ?? ''}  ·  ${deal['left'] ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (route != null)
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push(route);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _theme.accent,
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text('Dùng ưu đãi'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvent(Map<String, dynamic> event) {
    final isActive = event['isActive'] == true;
    return _OfferSurface(
      accent: _theme.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _theme.accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.card_giftcard_outlined, color: _theme.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String? ?? '',
                  style: const TextStyle(
                    color: Color(0xFF13263A),
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event['reward'] as String? ?? '',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${event['date'] ?? ''}  ·  ${event['participants'] ?? ''}',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                ),
                const SizedBox(height: 8),
                _DealTag(
                  text: isActive ? 'ĐANG DIỄN RA' : 'ĐÃ KẾT THÚC',
                  color: isActive ? _theme.accent : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(_PromotionTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: _OfferSurface(
        accent: theme.accent,
        child: Row(
          children: [
            Icon(theme.icon, color: theme.accent, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hiện chưa có ưu đãi đang áp dụng cho chủ đề này. Chương trình mới sẽ xuất hiện tại đây khi mở bán.',
                style: TextStyle(
                    color: Color(0xFF475569), fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color themeColor(dynamic value) {
    if (value is List<Color> && value.isNotEmpty) return value.first;
    if (value is List && value.isNotEmpty && value.first is Color) {
      return value.first as Color;
    }
    return _theme.accent;
  }
}

class _PromotionTheme {
  const _PromotionTheme({
    required this.key,
    required this.title,
    required this.eyebrow,
    required this.intro,
    required this.accent,
    required this.icon,
    required this.slides,
    this.catalog = const [],
    this.containedSlides = false,
  });

  final String key;
  final String title;
  final String eyebrow;
  final String intro;
  final Color accent;
  final IconData icon;
  final bool containedSlides;
  final List<_PromotionSlide> slides;
  final List<_CatalogItem> catalog;
}

class _CatalogItem {
  const _CatalogItem({
    required this.title,
    required this.detail,
    required this.badge,
    required this.icon,
    required this.route,
    required this.actionLabel,
    this.image,
  });

  final String title;
  final String detail;
  final String badge;
  final IconData icon;
  final String route;
  final String actionLabel;
  final String? image;
}

class _PromotionSlide {
  const _PromotionSlide({
    required this.image,
    required this.title,
    required this.detail,
    this.credit,
  });

  final String image;
  final String title;
  final String detail;
  final String? credit;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF13263A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _OfferSurface extends StatelessWidget {
  const _OfferSurface({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF0)),
        ),
        child: child,
      );
}

class _DealTag extends StatelessWidget {
  const _DealTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 155),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
}
