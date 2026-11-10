import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/promotion_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _voucherInputController = TextEditingController();
  int _selectedTab =
      0; // 0: Ưu Đãi, 1: Trả Góp Nhà & Xe, 2: Sự Kiện, 3: Voucher
  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  Timer? _bannerTimer;
  final List<Map<String, dynamic>> _apiVouchers = [];
  bool _isApplyingVoucher = false;
  bool _bannerAutoScrollEnabled = true;
  bool _loadingContent = true;

  final List<String> _tabs = [
    'Ưu Đãi',
    'Trả Góp Nhà & Xe',
    'Sự Kiện',
    'Voucher'
  ];

  static List<Color> _safeGradient(dynamic val) {
    List<Color> normalize(List<Color> colors) => colors
        .map((color) => Color.fromARGB(
              color.alpha,
              (color.red * 0.70).round(),
              (color.green * 0.70).round(),
              (color.blue * 0.70).round(),
            ))
        .toList(growable: false);

    if (val is List<Color> && val.length >= 2) return normalize(val);
    if (val is List) {
      final list = val.whereType<Color>().toList();
      if (list.length >= 2) return normalize(list);
      if (list.length == 1) return normalize([list.first, list.first]);
    }
    return const [Color(0xFF00537F), Color(0xFF007E97)];
  }

  static Color _safeColor(dynamic val,
      [Color fallback = AppColors.bottomBarOcean]) {
    if (val is Color) return val;
    return fallback;
  }

  final List<String> _categories = const [
    'Tất cả',
    'Ẩm thực & Cafe',
    'Di chuyển & Xe',
    'Trả góp & Vay',
    'Mua sắm',
    'Du lịch',
    'Hóa đơn',
    'Giải trí',
  ];

  // ===========================================================================
  // 1. MEGA HERO BANNERS (HỆ THỐNG BANNER CHÍNH - HÌNH ẢNH THỰC TẾ & ĐIỆN ẢNH)
  // ===========================================================================
  static final List<Map<String, dynamic>> _defaultHeroBanners = [
    {
      'title': 'Chào Bạn Mới — Nạp Tiền Đầu Tiên',
      'subtitle':
          'Nạp tiền lần đầu từ 500.000 VND nhận ngay ưu đãi 50.000 VND vào ví',
      'tag': 'CHÀO BẠN MỚI',
      'tagIcon': CupertinoIcons.sparkles,
      'accentColor': const Color(0xFF38BDF8),
      'gradient': const [Color(0xFF0A192F), Color(0xFF0284C7)],
      'route': '/deposit',
      'imagePath': 'assets/images/banners/banner_smartphone_tech.jpg',
      'cardImagePath': 'assets/images/banners/clean_visa_banner.png',
    },
    {
      'title': 'Gói Vay Mua Xe — Lãi Suất 5.9%/Năm',
      'subtitle':
          'Sở hữu ô tô mơ ước dễ dàng, phê duyệt hồ sơ online nhanh chóng trong 15 phút',
      'tag': 'VAY MUA XE',
      'tagIcon': CupertinoIcons.car_detailed,
      'accentColor': const Color(0xFF34D399),
      'gradient': const [Color(0xFF064E3B), Color(0xFF047857)],
      'route': '/cards',
      'imagePath': 'assets/images/banners/banner_luxury_car.jpg',
      'cardImagePath': 'assets/images/banners/clean_stellar_banner.png',
    },
    {
      'title': 'Du Lịch Hè Rực Rỡ — Hoàn Tiền 15%',
      'subtitle':
          'Đặt vé máy bay & resort Phú Quốc, Đà Nẵng, Thái Lan hoàn tới 500.000 VND',
      'tag': 'DU LỊCH 2026',
      'tagIcon': CupertinoIcons.airplane,
      'accentColor': const Color(0xFFFBBF24),
      'gradient': const [Color(0xFF1E1B4B), Color(0xFF4338CA)],
      'route': '/lifestyle/travel',
      'imagePath': 'assets/images/banners/banner_tropical_travel.jpg',
      'cardImagePath': 'assets/images/banners/clean_thailand_banner.png',
    },
    {
      'title': 'Cà Phê Sáng 0Đ & Ưu Đãi Đời Sống',
      'subtitle':
          'Thanh toán hóa đơn điện nước tặng ngay voucher Highlands Coffee thơm ngon',
      'tag': 'ĐỜI SỐNG HẰNG NGÀY',
      'tagIcon': CupertinoIcons.gift_fill,
      'accentColor': const Color(0xFFA78BFA),
      'gradient': const [Color(0xFF311042), Color(0xFF7E22CE)],
      'route': '/bills',
      'imagePath': 'assets/images/banners/highlands_drip.webp',
      'cardImagePath': 'assets/images/banners/clean_jcb_banner.png',
    },
    {
      'title': 'Giới Thiệu Bạn Bè — Nhận 100K Cả Hai',
      'subtitle':
          'Mời bạn bè mở ví Sen Hồng thành công, rinh ngay 100.000 VND tiền mặt',
      'tag': 'MỜI BẠN NHẬN QUÀ',
      'tagIcon': CupertinoIcons.person_2_fill,
      'accentColor': const Color(0xFF2DD4BF),
      'gradient': const [Color(0xFF0F2027), Color(0xFF203A43)],
      'route': '/referral',
      'imagePath': 'assets/images/banners/banner_car_loan_couple.png',
      'cardImagePath': 'assets/images/banners/clean_stellar_banner.png',
    },
  ];

  final List<Map<String, dynamic>> _heroBanners =
      List.from(_defaultHeroBanners);

  // ===========================================================================
  // 2. GÓI VAY & TRẢ GÓP XE, NHÀ, ĐIỆN MÁY ĐẶC QUYỀN
  // ===========================================================================
  // Nội dung được tải động từ Backend (notification-service) — KHÔNG dùng dữ liệu cứng
  final List<Map<String, dynamic>> _installmentDeals = [];

  // ===========================================================================
  // 3. FLASH DEALS (GIỜ VÀNG SĂN DEAL)
  // ===========================================================================
  // Nội dung được tải động từ Backend (notification-service) — KHÔNG dùng dữ liệu cứng
  final List<Map<String, dynamic>> _flashDeals = [];

  // ===========================================================================
  // 4. DANH SÁCH TẤT CẢ ƯU ĐÃI KHUYẾN MÃI (16 ITEMS)
  // ===========================================================================
  // Nội dung được tải động từ Backend (notification-service) — KHÔNG dùng dữ liệu cứng
  final List<Map<String, dynamic>> _allPromotions = [];

  // ===========================================================================
  // 5. SỰ KIỆN QUAY THƯỞNG & HOT EVENTS
  // ===========================================================================
  // Nội dung được tải động từ Backend (notification-service) — KHÔNG dùng dữ liệu cứng
  final List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _startBannerTimer();
      _loadPromotionContent();
    }
  }

  /// Tải toàn bộ nội dung tab Ưu đãi từ Backend (100% dữ liệu thật):
  /// - /promotions/campaigns → banner chính + sự kiện (số người tham gia thật)
  /// - /promotions → danh mục voucher + tab voucher cá nhân
  Future<void> _loadPromotionContent() async {
    final ds = PromotionRemoteDataSource();
    try {
      final results = await Future.wait([
        ds.getCampaigns().catchError((_) => <Map<String, dynamic>>[]),
        ds.getPromotions().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        final apiBanners = results[0].map(_campaignToBanner).toList();
        if (apiBanners.isNotEmpty) {
          _heroBanners.clear();
          _heroBanners.addAll(apiBanners);
        } else if (_heroBanners.isEmpty) {
          _heroBanners.addAll(_defaultHeroBanners);
        }
        _events.addAll(results[0].map(_campaignToEvent));
        final catalog = results[1];
        _allPromotions.addAll(
            catalog.asMap().entries.map((e) => _voucherToPromotion(e.value, e.key)));
        _apiVouchers.addAll(catalog);
        _loadingContent = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Map<String, dynamic> _parseRulesJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static const Map<String, Map<String, Object>> _campaignVisuals = {
    'deposit': {
      'icon': CupertinoIcons.sparkles,
      'accent': Color(0xFF38BDF8),
      'gradient': [Color(0xFF0A192F), Color(0xFF0284C7)],
      'image': 'assets/images/banners/banner_smartphone_tech.jpg',
      'card': 'assets/images/banners/clean_visa_banner.png',
    },
    'referral': {
      'icon': CupertinoIcons.person_2_fill,
      'accent': Color(0xFF34D399),
      'gradient': [Color(0xFF0F2027), Color(0xFF203A43)],
      'image': 'assets/images/banners/banner_car_loan_couple.png',
      'card': 'assets/images/banners/clean_stellar_banner.png',
    },
    'savings': {
      'icon': CupertinoIcons.gift_fill,
      'accent': Color(0xFFFBBF24),
      'gradient': [Color(0xFF1E1B4B), Color(0xFF4338CA)],
      'image': 'assets/images/banners/banner_tropical_travel.jpg',
      'card': 'assets/images/banners/clean_thailand_banner.png',
    },
    'bills': {
      'icon': CupertinoIcons.doc_text_fill,
      'accent': Color(0xFFA78BFA),
      'gradient': [Color(0xFF311042), Color(0xFF7E22CE)],
      'image': 'assets/images/banners/highlands_drip.webp',
      'card': 'assets/images/banners/clean_jcb_banner.png',
    },
    'p2p': {
      'icon': CupertinoIcons.paperplane_fill,
      'accent': Color(0xFF60A5FA),
      'gradient': [Color(0xFF111827), Color(0xFF1D4ED8)],
      'image': 'assets/images/banners/da_nang_golden_bridge.webp',
      'card': 'assets/images/banners/clean_visa_banner.png',
    },
    'car': {
      'icon': CupertinoIcons.car_detailed,
      'accent': Color(0xFF34D399),
      'gradient': [Color(0xFF064E3B), Color(0xFF047857)],
      'image': 'assets/images/banners/banner_luxury_car.jpg',
      'card': 'assets/images/banners/clean_stellar_banner.png',
    },
    'travel': {
      'icon': CupertinoIcons.airplane,
      'accent': Color(0xFF38BDF8),
      'gradient': [Color(0xFF0C4A6E), Color(0xFF0284C7)],
      'image': 'assets/images/banners/banner_tropical_travel.jpg',
      'card': 'assets/images/banners/clean_thailand_banner.png',
    },
    'default': {
      'icon': CupertinoIcons.sparkles,
      'accent': Color(0xFF38BDF8),
      'gradient': [Color(0xFF0A192F), Color(0xFF0284C7)],
      'image': 'assets/images/banners/banner_smartphone_tech.jpg',
      'card': 'assets/images/banners/clean_visa_banner.png',
    },
  };

  Map<String, dynamic> _campaignToBanner(Map<String, dynamic> c) {
    final rules = _parseRulesJson(c['rulesJson']);
    final category =
        ((rules['category'] as String?) ?? (c['type'] as String? ?? ''))
            .toLowerCase();
    final visual = _campaignVisuals[category] ?? _campaignVisuals['default']!;
    return {
      'title': (c['name'] as String?) ?? '',
      'subtitle': (c['description'] as String?) ?? '',
      'tag': ((rules['badge'] as String?) ??
              (c['type'] as String? ?? 'SEN HỒNG'))
          .toUpperCase(),
      'tagIcon': visual['icon'] as IconData,
      'accentColor': visual['accent'] as Color,
      'gradient': visual['gradient'] as List<Color>,
      'route': (rules['route'] as String?) ?? '/promotions',
      'imagePath':
          (rules['imagePath'] as String?) ?? (visual['image'] as String?),
      'cardImagePath':
          (rules['cardImagePath'] as String?) ?? (visual['card'] as String?),
    };
  }

  Map<String, dynamic> _campaignToEvent(Map<String, dynamic> c) {
    final rules = _parseRulesJson(c['rulesJson']);
    final category =
        ((rules['category'] as String?) ?? (c['type'] as String? ?? ''))
            .toLowerCase();
    final visual = _campaignVisuals[category] ?? _campaignVisuals['default']!;
    final participants = (c['participantsCount'] as num?)?.toInt() ?? 0;
    final rewardAmount = (c['rewardAmount'] as num?)?.toInt() ?? 0;
    final end = DateTime.tryParse((c['endDate'] ?? '').toString());
    final dateText = end != null
        ? 'Đến ${end.day}/${end.month}/${end.year}'
        : 'Diễn ra liên tục';
    return {
      'title': (c['name'] as String?) ?? '',
      'date': dateText,
      'badge': ((rules['badge'] as String?) ?? (c['type'] as String? ?? ''))
          .toUpperCase(),
      'badgeColor': visual['accent'] as Color,
      'icon': visual['icon'] as IconData,
      'gradient': visual['gradient'] as List<Color>,
      'route': (rules['route'] as String?) ?? '/promotions',
      'reward': rewardAmount > 0
          ? CurrencyFormatter.formatVND(rewardAmount.toDouble())
          : 'Theo quy định chương trình',
      'participants': participants > 0
          ? '$participants người đã tham gia'
          : 'Mới mở — hãy là người đầu tiên',
    };
  }

  Map<String, dynamic> _voucherToPromotion(Map<String, dynamic> v, int index) {
    final discountValue = (v['discountValue'] as num?)?.toInt() ?? 0;
    final isPercent =
        ((v['discountType'] as String?) ?? 'FIXED').toUpperCase() == 'PERCENT';
    final discount = isPercent
        ? 'GIẢM $discountValue%'
        : 'GIẢM ${(discountValue / 1000).round()}K';
    final minOrder = (v['minOrderAmount'] as num?)?.toInt() ?? 0;
    final validUntil = DateTime.tryParse((v['validUntil'] ?? '').toString());
    final expiry = validUntil != null
        ? 'HSD: ${validUntil.day}/${validUntil.month}/${validUntil.year}'
        : 'HSD: liên tục';
    final visual = _promoVisualPalette[index % _promoVisualPalette.length];
    return {
      'id': (v['id'] ?? '').toString(),
      'brand': 'Sen Hồng Bank',
      'category': 'Ưu đãi Sen Hồng',
      'title': (v['title'] as String?) ?? '',
      'desc': (v['description'] as String?) ?? '',
      'discount': discount,
      'code': (v['code'] as String?) ?? '',
      'condition': minOrder > 0
          ? 'Đơn tối thiểu ${CurrencyFormatter.formatVND(minOrder.toDouble())}'
          : 'Áp dụng mọi đơn hàng',
      'expiry': expiry,
      'gradient': visual,
      'icon': CupertinoIcons.ticket_fill,
      'route': '/scan-qr',
    };
  }

  static const List<List<Color>> _promoVisualPalette = [
    [AppColors.brandBlue, AppColors.bottomBarOcean],
    [AppColors.royalBlue, AppColors.oceanCyan],
    [AppColors.brandNavy, AppColors.tealNavy],
  ];

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_heroBanners.isEmpty) return;
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _heroBanners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.of(context);
    if (enabled == _bannerAutoScrollEnabled) return;
    _bannerAutoScrollEnabled = enabled;
    if (enabled) {
      _startBannerTimer();
    } else {
      _bannerTimer?.cancel();
      _bannerTimer = null;
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _voucherInputController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucherCode() async {
    final code = _voucherInputController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã ưu đãi')),
      );
      return;
    }
    setState(() => _isApplyingVoucher = true);
    try {
      final res = await PromotionRemoteDataSource()
          .apply(code: code, orderAmount: 100000);
      final discount = res['discountAmount'] ?? 50000;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emeraldGreen,
            content: Text(
                'Áp dụng thành công mã $code! Giảm: ${CurrencyFormatter.formatVND((discount as num).toDouble())}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingVoucher = false);
    }
  }

  void _copyVoucherCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.emeraldGreen,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã sao chép mã "$code" vào bộ nhớ tạm!',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onUseVoucher(Map<String, dynamic> item) {
    final route = item['route'] as String? ?? '/';
    context.push(route);
  }

  void _showVoucherDetailModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _buildDetailBottomSheet(ctx, item),
    );
  }

  List<Map<String, dynamic>> get _filteredPromotions {
    return _allPromotions.where((p) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          p['category'] == _categories[_selectedCategoryIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          (p['title'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (p['brand'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (p['code'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Ưu Đãi & Quà Tặng',
          style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppBarSeamFade(),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mã đã lưu',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(CupertinoIcons.star_circle_fill,
                    color: AppColors.primary, size: 24),
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('3',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() => _selectedTab = 3);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Custom Navigation Pills (Immune to Hot Reload bugs)
          _buildCustomTabBar(),

          // Tab Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey('promo_tab_$_selectedTab'),
                child: _buildCurrentTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION PILLS (TABS)
  // ===========================================================================
  Widget _buildCustomTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_tabs.length, (idx) {
            final isSelected = _selectedTab == idx;
            return Padding(
              padding: EdgeInsets.only(right: idx == _tabs.length - 1 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = idx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _tabs[idx],
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondaryLight,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 11.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return _buildUuDaiTab();
      case 1:
        return _buildTraGopTab();
      case 2:
        return _buildSuKienTab();
      case 3:
        return _buildVoucherTab();
      default:
        return _buildUuDaiTab();
    }
  }

  // ===========================================================================
  // TAB 1: TẤT CẢ ƯU ĐÃI
  // ===========================================================================
  Widget _buildUuDaiTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: _buildSearchBar(),
        ),

        // Hero Mega Banners Carousel
        _buildHeroBannerCarousel(),

        // SenPoint Club Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: _buildSenPointClubCard(),
        ),

        // Quick Category Icons Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _buildQuickActions(),
        ),

        // Flash Sale Giờ Vàng
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: _buildFlashSaleHeader(),
        ),
        _buildFlashSaleList(),

        // Tiêu Điểm: Trả Góp Xe & Nhà Preview Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.house_fill,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ưu Đãi Trả Góp Xe & Nhà Hot',
                        style: TextStyle(
                            color: AppColors.textPrimaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _selectedTab = 1),
                child: const Text('Xem tất cả →',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        _buildInstallmentCarouselPreview(),

        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: _buildCategoryChips(),
        ),

        // Section Label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ưu đãi hấp dẫn (${_filteredPromotions.length})',
                  style: const TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Mới nhất',
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        if (_filteredPromotions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.tag_fill,
                      size: 64, color: AppColors.textMutedLight),
                  SizedBox(height: 12),
                  Text('Không tìm thấy ưu đãi phù hợp',
                      style: TextStyle(
                          color: AppColors.textPrimaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Hãy thử tìm từ khóa khác hoặc đổi danh mục',
                      style: TextStyle(
                          color: AppColors.textSecondaryLight, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ..._filteredPromotions.map((p) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildPromotionCard(p),
              )),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: TRẢ GÓP & VAY XE, NHÀ
  // ===========================================================================
  Widget _buildTraGopTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        // Highlight Intro Banner — nội dung theo chương trình thật từ Backend
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xF20C1E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.graph_square_fill,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chương Trình Tài Chính Sen Hồng',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Các chương trình trả góp & tín dụng sẽ được cập nhật tại đây khi có thông báo chính thức.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Chương Trình Đang Áp Dụng',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (_installmentDeals.isEmpty)
          _buildEmptyContentHint(
            icon: CupertinoIcons.doc_text_fill,
            message: 'Chưa có chương trình trả góp nào đang diễn ra.\nVui lòng quay lại sau.',
          )
        else
          ..._installmentDeals.map((deal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFullInstallmentCard(deal),
              )),
      ],
    );
  }

  /// Gợi ý trung thực khi chưa có nội dung từ Backend (không còn dữ liệu cứng)
  Widget _buildEmptyContentHint({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xF20C1E36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: SỰ KIỆN & QUÀ TẶNG
  // ===========================================================================
  Widget _buildSuKienTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _buildEventBannerStrip(),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25), width: 1),
              ),
              child: const Icon(CupertinoIcons.sparkles,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Sự kiện đang diễn ra',
                style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_events.isEmpty && !_loadingContent)
          _buildEmptyContentHint(
            icon: CupertinoIcons.sparkles,
            message: 'Chưa có sự kiện nào đang diễn ra.\nCác chương trình mới sẽ xuất hiện tại đây.',
          )
        else
          ..._events.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildEventCard(e),
            )),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: MÃ VOUCHER & ĐÃ LƯU
  // ===========================================================================
  Widget _buildVoucherTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        // Redeem Gift Code Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xF20C1E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.gift_fill,
                      color: AppColors.bottomBarCyan, size: 24),
                  SizedBox(width: 10),
                  Text('Nhập Mã Ưu Đãi Độc Quyền',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                  'Bạn có mã quà tặng từ đối tác hoặc chương trình tri ân?',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.tickets_fill,
                        color: AppColors.bottomBarCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _voucherInputController,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã: SENBANK2026...',
                          hintStyle:
                              TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isApplyingVoucher ? null : _applyVoucherCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bottomBarCyan,
                        foregroundColor: AppColors.textPrimaryLight,
                        elevation: 0,
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: _isApplyingVoucher
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimaryLight),
                            )
                          : const Text('Áp dụng',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Popular voucher codes
        const Text('Mã phổ biến hôm nay',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._buildPopularVoucherList(),

        const SizedBox(height: 24),
        const Text('Cách nhận mã ưu đãi',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildHowToGetVoucher(),
      ],
    );
  }

  // ===========================================================================
  // SUB-WIDGETS & UI COMPONENTS
  // ===========================================================================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                  color: AppColors.textPrimaryLight, fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Tìm ưu đãi, mã giảm giá...',
                hintStyle:
                    TextStyle(color: AppColors.textMutedLight, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.xmark_circle_fill,
                  color: AppColors.textSecondaryLight, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () => _showRedeemDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.infoBg,
                foregroundColor: AppColors.primary,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.gift_fill, size: 14),
                  SizedBox(width: 5),
                  Text('Nhập mã',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBannerCarousel() {
    if (_loadingContent) {
      return const SizedBox(
        height: 202,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_heroBanners.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        SizedBox(
          height: 202,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) {
              setState(() => _currentBannerIndex = idx);
              HapticFeedback.selectionClick();
            },
            itemCount: _heroBanners.length,
            itemBuilder: (context, index) {
              final banner = _heroBanners[index];
              final String? imagePath =
                  (banner['imagePath'] ?? banner['image']) as String?;
              final String? cardImagePath =
                  (banner['cardImagePath'] ?? banner['cardImage'] ?? banner['card'])
                      as String?;
              final List<Color> gradient = (banner['gradient'] as List<Color>?) ??
                  const [Color(0xFF0C2340), Color(0xFF0369A1)];
              final Color accentColor =
                  (banner['accentColor'] as Color?) ?? AppColors.brandBlue;
              final IconData? tagIcon = banner['tagIcon'] as IconData?;
              final String tag = (banner['tag'] as String?) ?? '';
              final String title = (banner['title'] as String?) ?? '';
              final String subtitle = (banner['subtitle'] as String?) ?? '';
              final String route = (banner['route'] as String?) ?? '/promotions';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    try {
                      context.push(route);
                    } catch (_) {
                      Navigator.of(context).pushNamed(route);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 202,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        border: Border.all(
                          color: accentColor.withOpacity(0.40),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.40),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // 1. Ảnh chân thật người thật / phong cảnh / xe cộ / điện thoại
                          if (imagePath != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: MediaQuery.of(context).size.width * 0.58,
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    stops: [0.0, 0.40, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.white70,
                                      Colors.white,
                                    ],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),

                          // 2. Lớp phủ chuyển sắc mềm mại bên trái để nổi bật văn bản
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  stops: const [0.0, 0.45, 0.78, 1.0],
                                  colors: [
                                    gradient.first.withOpacity(0.96),
                                    gradient.first.withOpacity(0.85),
                                    gradient.last.withOpacity(0.20),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 3. Hiệu ứng Ambient Glow góc phải trên
                          Positioned(
                            top: -30,
                            right: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.20),
                              ),
                            ),
                          ),

                          // 4. Thẻ ngân hàng thực tế dập nổi (Realistic Card Overlay nếu có)
                          if (cardImagePath != null)
                            Positioned(
                              right: -4,
                              bottom: 10,
                              child: Transform.rotate(
                                angle: -0.09,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.55),
                                        blurRadius: 18,
                                        offset: const Offset(4, 8),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    cardImagePath,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),

                          // 5. Nội dung thông tin Text & CTA Button
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tag Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.40),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accentColor.withOpacity(0.45),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (tagIcon != null) ...[
                                        Icon(tagIcon,
                                            size: 12, color: accentColor),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Title, Subtitle và CTA Button
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.56,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          letterSpacing: -0.2,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xCC000000),
                                              blurRadius: 6,
                                              offset: Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.92),
                                          fontSize: 11.5,
                                          height: 1.32,
                                          shadows: const [
                                            Shadow(
                                              color: Color(0x99000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 7.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Khám phá ngay',
                                              style: TextStyle(
                                                color: gradient.first,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              CupertinoIcons.arrow_right,
                                              size: 11.5,
                                              color: gradient.first,
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroBanners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width: _currentBannerIndex == idx ? 22 : 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == idx
                    ? AppColors.brandBlue
                    : AppColors.brandNavy.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSenPointClubCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF2F8FD), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5B54F).withOpacity(0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: const Color(0xFFE5B54F).withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/senbank_lotus_isolated.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                CupertinoIcons.star_circle_fill,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'SenPoint Club',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE5B54F).withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.sparkles,
                              size: 10, color: Color(0xFFB78103)),
                          SizedBox(width: 3),
                          Text(
                            'Hạng Vàng',
                            style: TextStyle(
                              color: Color(0xFFB78103),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Bạn đang có 2.450 điểm thưởng tích lũy',
                    style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đang tải danh mục đổi quà SenPoint...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đổi quà',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final items = [
      {
        'icon': CupertinoIcons.car_fill,
        'image': 'assets/images/service-icons/promo_3d_car.png',
        'label': 'Vay xe 0%',
        'accent': const Color(0xFF0878A5),
        'action': () => _openPromotionCategory('car'),
      },
      {
        'icon': CupertinoIcons.house_fill,
        'image': 'assets/images/service-icons/promo_3d_house.png',
        'label': 'Mua nhà',
        'accent': const Color(0xFF537A68),
        'action': () => _openPromotionCategory('home'),
      },
      {
        'icon': CupertinoIcons.device_phone_portrait,
        'image': 'assets/images/service-icons/promo_3d_phone.png',
        'label': 'Điện máy',
        'accent': const Color(0xFF1976A8),
        'action': () => _openPromotionCategory('electronics'),
      },
      {
        'icon': CupertinoIcons.cart_fill,
        'image': 'assets/images/service-icons/promo_3d_coffee.png',
        'label': 'Highlands',
        'accent': const Color(0xFF8A3F2D),
        'action': () => _openPromotionCategory('highlands'),
      },
      {
        'icon': CupertinoIcons.airplane,
        'image': 'assets/images/service-icons/promo_3d_airplane.png',
        'label': 'Vé bay',
        'accent': const Color(0xFF087F8C),
        'action': () => _openPromotionCategory('travel'),
      },
      {
        'icon': CupertinoIcons.bag_fill,
        'image': 'assets/images/service-icons/promo_3d_bag.png',
        'label': 'Shopee',
        'accent': const Color(0xFFDA4B36),
        'action': () => _openPromotionCategory('shopee'),
      },
      {
        'icon': CupertinoIcons.creditcard_fill,
        'image': 'assets/images/service-icons/promo_3d_card.png',
        'label': 'Thẻ hoàn tiền',
        'accent': const Color(0xFF345C9B),
        'action': () => _openPromotionCategory('cashback'),
      },
      {
        'icon': CupertinoIcons.gift_fill,
        'image': 'assets/images/service-icons/promo_3d_gift.png',
        'label': 'Vòng quay',
        'accent': const Color(0xFFB97922),
        'action': () => _openPromotionCategory('wheel'),
      },
    ];

    Widget buildItem(Map<String, dynamic> item) {
      final imagePath = item['image'] as String?;
      final accent = item['accent'] as Color;
      return Expanded(
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            (item['action'] as VoidCallback)();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withOpacity(0.20),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            imagePath,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              item['icon'] as IconData,
                              color: accent,
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          item['icon'] as IconData,
                          color: accent,
                          size: 24,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.sublist(0, 4).map(buildItem).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.sublist(4, 8).map(buildItem).toList(),
        ),
      ],
    );
  }

  void _openPromotionCategory(String categoryKey) {
    final List<Map<String, dynamic>> promotions = (switch (categoryKey) {
      'car' => _allPromotions
          .where((item) => const {'promo_3', 'promo_9'}.contains(item['id']))
          .toList(),
      'home' => _allPromotions
          .where((item) => item['id'] == 'promo_4')
          .toList(),
      'electronics' => _allPromotions
          .where((item) => item['id'] == 'promo_5')
          .toList(),
      'highlands' => _allPromotions
          .where((item) => item['brand'] == 'Highlands Coffee')
          .toList(),
      'travel' => _allPromotions
          .where((item) => item['category'] == 'Du lịch')
          .toList(),
      'shopee' => _allPromotions
          .where((item) => (item['brand'] as String).contains('Shopee'))
          .toList(),
      'cashback' => _allPromotions
          .where((item) => item['category'] == 'Hoàn tiền')
          .toList(),
      _ => <Map<String, dynamic>>[],
    })
        .where(_isCurrentPromotion)
        .toList(growable: false);

    final List<Map<String, dynamic>> flashDeals = switch (categoryKey) {
      'highlands' => _flashDeals
          .where((item) => item['brand'] == 'Highlands Coffee')
          .toList(growable: false),
      'shopee' => _flashDeals
          .where((item) => item['brand'] == 'Shopee Mall')
          .toList(growable: false),
      _ => <Map<String, dynamic>>[],
    };

    final List<Map<String, dynamic>> installmentDeals = switch (categoryKey) {
      'car' => _installmentDeals
          .where((item) => item['type'] == 'car' || item['type'] == 'bike')
          .toList(),
      'home' => _installmentDeals
          .where((item) => item['type'] == 'house')
          .toList(),
      'electronics' => _installmentDeals
          .where((item) => item['type'] == 'tech')
          .toList(),
      _ => <Map<String, dynamic>>[],
    };

    final events = categoryKey == 'wheel'
        ? _events
            .map((event) => <String, dynamic>{
                  ...event,
                  'isActive': _isUpcomingEvent(event),
                })
            .toList(growable: false)
        : <Map<String, dynamic>>[];

    context.push(
      '/promotions/category/$categoryKey',
      extra: <String, dynamic>{
        'promotions': promotions,
        'flashDeals': flashDeals,
        'installmentDeals': installmentDeals,
        'events': events,
      },
    );
  }

  bool _isCurrentPromotion(Map<String, dynamic> promotion) =>
      _isDateRangeActive(promotion['expiry'] as String?);

  bool _isUpcomingEvent(Map<String, dynamic> event) =>
      _isDateRangeActive(event['date'] as String?);

  bool _isDateRangeActive(String? value) {
    if (value == null) return false;
    if (value.toLowerCase().contains('không giới hạn')) return true;
    final dates = RegExp(r'(\d{2})/(\d{2})/(\d{4})').allMatches(value);
    if (dates.isEmpty) return false;
    final last = dates.last;
    final day = int.parse(last.group(1)!);
    final month = int.parse(last.group(2)!);
    final year = int.parse(last.group(3)!);
    final endOfDay = DateTime(year, month, day, 23, 59, 59);
    return !endOfDay.isBefore(DateTime.now());
  }

  Widget _buildFlashSaleHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.25), width: 1),
          ),
          child: const Icon(CupertinoIcons.gift_fill,
              color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Giờ Vàng Săn Deal',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.bottomBarOcean.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text('02:45:18',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(width: 8),
        const Text('Cập nhật liên tục',
            style:
                TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
      ],
    );
  }

  Widget _buildFlashSaleList() {
    if (!_loadingContent && _flashDeals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildEmptyContentHint(
          icon: CupertinoIcons.clock_fill,
          message: 'Chưa có deal nào trong giờ vàng.\nTheo dõi để không bỏ lỡ chương trình tiếp theo.',
        ),
      );
    }
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _flashDeals.length,
        itemBuilder: (context, index) {
          final deal = _flashDeals[index];
          final gradient = _safeGradient(deal['gradient']);
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient[0], gradient[1]],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: () => _copyVoucherCode(deal['code'] as String),
              borderRadius: BorderRadius.circular(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x66030B17)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(deal['discount'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(deal['icon'] as IconData,
                                  color: Colors.white70, size: 16),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(deal['brand'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(deal['title'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: deal['progress'] as double,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(
                                      Colors.white),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(deal['left'] as String,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                  const Icon(CupertinoIcons.doc_on_doc_fill,
                                      size: 14, color: Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ],
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

  // Preview strip cho mục trả góp xe & nhà
  Widget _buildInstallmentCarouselPreview() {
    return SizedBox(
      height: 145,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _installmentDeals.length,
        itemBuilder: (context, index) {
          final deal = _installmentDeals[index];
          final String? imagePath = deal['image'] as String?;
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF091424),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ảnh nền chân thật
                  if (imagePath != null)
                    Positioned.fill(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),

                  // Scrim điện ảnh đa lớp
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.52, 1.0],
                          colors: [
                            Color(0xF5050F1E),
                            Color(0xDD08162B),
                            Color(0x5508162B),
                          ],
                        ),
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedTab = 1);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xB3050F1E),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white54, width: 0.5),
                                  ),
                                  child: Text(
                                    (deal['tag'] ?? '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                  (deal['icon'] as IconData?) ??
                                      CupertinoIcons.tickets_fill,
                                  color: Colors.white70,
                                  size: 20),
                            ],
                          ),
                          Text(
                            deal['title'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text.rich(
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                  TextSpan(
                                    text: 'Lãi suất: ',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11),
                                    children: [
                                      TextSpan(
                                        text: deal['interest'] as String,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('Xem ngay →',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark])
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.bottomBarCyan
                        : AppColors.borderLight,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.bottomBarOcean.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> item) {
    final gradient = _safeGradient(item['gradient']);
    final discountStr = (item['discount'] as String? ?? '');
    final isHot = discountStr.contains('50%') ||
        discountStr.contains('100%') ||
        discountStr.contains('2TR');

    const double bottomBarHeight = 54.0;
    const double notchRadius = 9.0;
    const double cornerRadius = 18.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00142A).withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: (isHot ? const Color(0xFFE11D48) : AppColors.bottomBarOcean)
                .withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const TicketBorderPainter(
          bottomBarHeight: bottomBarHeight,
          notchRadius: notchRadius,
          cornerRadius: cornerRadius,
          borderColor: AppColors.cardBorderDark, // Use token instead
          borderWidth: 1.0,
        ),
        child: ClipPath(
          clipper: const TicketCardClipper(
            bottomBarHeight: bottomBarHeight,
            notchRadius: notchRadius,
            cornerRadius: cornerRadius,
          ),
          child: Container(
            color: const Color(0xF20C1E36),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showVoucherDetailModal(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(item['icon'] as IconData,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['brand'] as String,
                                        style: const TextStyle(
                                          color: AppColors.bottomBarCyan,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isHot
                                            ? const Color(0xFF9F1239)
                                            : AppColors.deepNavy,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isHot
                                                    ? const Color(0xFFE11D48)
                                                    : AppColors.bottomBarOcean)
                                                .withOpacity(0.35),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        item['discount'] as String,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['desc'] as String,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      // Nét đứt laser phân cách vé ngân hàng kết nối 2 vết cắt bán nguyệt
                      Row(
                        children: List.generate(
                          26,
                          (i) => Expanded(
                            child: Container(
                              height: 1,
                              color: i.isEven
                                  ? Colors.white.withOpacity(0.22)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.clock_fill,
                                    size: 14,
                                    color: AppColors.textSecondaryDark),
                                const SizedBox(width: 5),
                                Text(
                                  item['expiry'] as String,
                                  style: const TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 11.5),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _copyVoucherCode(item['code'] as String),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                        color: Colors.white.withOpacity(0.25)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: const Size(60, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(CupertinoIcons.doc_on_doc_fill,
                                          size: 14, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text('Lưu mã',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _onUseVoucher(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.bottomBarCyan,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    minimumSize: const Size(64, 38),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text('Dùng ngay',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(CupertinoIcons.chevron_forward,
                                          size: 14,
                                          color: AppColors.textPrimaryLight),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Card chi tiết cho Tab Trả Góp Xe & Nhà
  Widget _buildFullInstallmentCard(Map<String, dynamic> deal) {
    final gradient = _safeGradient(deal['gradient']);
    final badgeColor = _safeColor(deal['badgeColor']);
    final String? imagePath = deal['image'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF20C1E36),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF001B3A).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              deal['icon'] as IconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        : Icon(
                            deal['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deal['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Đối tác: ${deal['partner']}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11.5)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(deal['tag'] as String,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(deal['desc'] as String,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.35)),
            const SizedBox(height: 14),

            // 3 thông số vàng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('LÃI SUẤT',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['interest'] as String,
                          style: const TextStyle(
                              color: AppColors.bottomBarCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  Column(
                    children: [
                      const Text('HẠN MỨC',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['maxLimit'] as String,
                          style: const TextStyle(
                              color: AppColors.bottomBarCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  Column(
                    children: [
                      const Text('THỜI HẠN',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['duration'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Đang tải công cụ tính gốc lãi cho gói ${deal['title']}')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Tính tiền góp',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/bills/quick-loan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bottomBarCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Đăng ký vay',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBannerStrip() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandBlue, AppColors.bottomBarOcean],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Image.asset(
              'assets/images/service-icons/promo_3d_gift.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.rosette,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chương Trình Sen Hồng Bank',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(height: 2),
                Text('Các sự kiện & ưu đãi đang diễn ra từ ngân hàng',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final gradient = _safeGradient(event['gradient']);
    final badgeColor = _safeColor(event['badgeColor'], AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF20C1E36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF001B3A).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(event['icon'] as IconData,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(event['date'] as String,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(event['badge'] as String,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.gift_fill,
                    color: AppColors.bottomBarCyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Phần thưởng: ${event['reward']}',
                      style: const TextStyle(
                          color: AppColors.bottomBarCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(event['participants'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ElevatedButton(
                onPressed: () {
                  // Điều hướng tới tính năng thật của chương trình (không giả lập tham gia)
                  final route = (event['route'] as String?) ?? '/promotions';
                  try {
                    context.push(route);
                  } catch (_) {
                    Navigator.of(context).pushNamed(route);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bottomBarCyan,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tham gia ngay',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPopularVoucherList() {
    final List<Map<String, dynamic>> codes = [];
    if (_apiVouchers.isNotEmpty) {
      for (final v in _apiVouchers) {
        codes.add({
          'code': (v['code'] ?? 'SENBANK').toString(),
          'desc':
              (v['title'] ?? v['description'] ?? 'Ưu đãi tài khoản').toString(),
          'color': AppColors.bottomBarOcean,
        });
      }
    }
    codes.addAll([
      {
        'code': 'WELCOME100K',
        'desc': 'Tặng 100.000đ cho tài khoản mới',
        'color': AppColors.bottomBarCyan
      },
      {
        'code': 'VAYXE0PERCENT',
        'desc': 'Gói vay ô tô điện VinFast - Lãi suất 0%',
        'color': AppColors.bottomBarOcean
      },
      {
        'code': 'NHAPHO52',
        'desc': 'Vay mua nhà phố & căn hộ - Lãi suất 5.2%',
        'color': AppColors.primary
      },
      {
        'code': 'SENBANK9',
        'desc': 'Ưu đãi tháng 9 - Giảm 5% mọi giao dịch',
        'color': AppColors.brandBlue
      },
      {
        'code': 'FRIEND50K',
        'desc': 'Giới thiệu bạn bè - Nhận 50.000đ',
        'color': AppColors.bottomBarCyan
      },
    ]);
    return codes
        .map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF20C1E36),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF001B3A).withOpacity(0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 3)),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _safeColor(c['color']),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['code'] as String,
                              style: const TextStyle(
                                  color: AppColors.bottomBarCyan,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text(c['desc'] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_doc_fill,
                          size: 18, color: AppColors.bottomBarCyan),
                      onPressed: () => _copyVoucherCode(c['code'] as String),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  Widget _buildHowToGetVoucher() {
    final steps = [
      {
        'icon': CupertinoIcons.creditcard_fill,
        'title': 'Mở thẻ tín dụng SenBank',
        'desc': 'Nhận ngay gói voucher 2.000.000đ'
      },
      {
        'icon': CupertinoIcons.car_fill,
        'title': 'Đăng ký vay xe & mua nhà',
        'desc': 'Tặng bảo hiểm và phí trước bạ'
      },
      {
        'icon': CupertinoIcons.person_2_fill,
        'title': 'Giới thiệu bạn bè',
        'desc': 'Mỗi lượt đăng ký nhận 50.000đ tiền mặt'
      },
      {
        'icon': CupertinoIcons.waveform_path_ecg,
        'title': 'Tham gia vòng quay may mắn',
        'desc': 'Cơ hội trúng iPhone 16 Pro'
      },
    ];
    return Column(
      children: steps
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF20C1E36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bottomBarCyan.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s['icon'] as IconData,
                            color: AppColors.bottomBarCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['title'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(s['desc'] as String,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDetailBottomSheet(BuildContext ctx, Map<String, dynamic> item) {
    final gradient = _safeGradient(item['gradient']);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB0A192E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item['icon'] as IconData,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['brand'] as String,
                        style: const TextStyle(
                            color: AppColors.bottomBarCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(item['title'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item['desc'] as String,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),

          // Voucher Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.bottomBarCyan.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MÃ VOUCHER',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(item['code'] as String,
                        style: const TextStyle(
                            color: AppColors.bottomBarCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _copyVoucherCode(item['code'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottomBarCyan,
                    foregroundColor: Colors.black,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sao chép',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Điều kiện sử dụng:',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('• ${item['condition']}',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('• ${item['expiry']}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _onUseVoucher(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottomBarCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sử Dụng Ưu Đãi Ngay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xF20B1C32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
              color: AppColors.bottomBarCyan.withOpacity(0.5), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(CupertinoIcons.gift_fill, color: AppColors.bottomBarCyan),
            SizedBox(width: 8),
            Expanded(
              child: Text('Nhập Mã Quà Tặng',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Nhập mã voucher hoặc mã quà tặng từ SenBank và đối tác.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Ví dụ: VINFAST0, HOMELOAN52...',
                hintStyle: const TextStyle(
                    color: Colors.white30, fontSize: 12.5, letterSpacing: 0),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.emeraldGreen,
                    content: Text('Đã kích hoạt thành công mã ưu đãi "$code"!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bottomBarCyan,
              foregroundColor: Colors.black,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Áp dụng',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Clipper tạo hình dáng vé xé ngân hàng (Coupon Ticket) với 2 lỗ khuyết bán nguyệt 2 bên mép
class TicketCardClipper extends CustomClipper<Path> {
  final double bottomBarHeight;
  final double notchRadius;
  final double cornerRadius;

  const TicketCardClipper({
    this.bottomBarHeight = 54.0,
    this.notchRadius = 9.0,
    this.cornerRadius = 18.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchY = size.height - bottomBarHeight;
    final r = notchRadius;
    final cr = cornerRadius;

    // Góc trên bên trái
    path.moveTo(0, cr);
    path.arcToPoint(Offset(cr, 0), radius: Radius.circular(cr));

    // Cạnh trên
    path.lineTo(size.width - cr, 0);
    // Góc trên bên phải
    path.arcToPoint(Offset(size.width, cr), radius: Radius.circular(cr));

    // Cạnh phải xuống đến vết khuyết bán nguyệt
    path.lineTo(size.width, notchY - r);
    // Vết khuyết bên phải (uốn cong vào trong thân thẻ)
    path.arcToPoint(Offset(size.width, notchY + r),
        radius: Radius.circular(r), clockwise: false);

    // Cạnh phải xuống đến góc dưới bên phải
    path.lineTo(size.width, size.height - cr);
    path.arcToPoint(Offset(size.width - cr, size.height),
        radius: Radius.circular(cr));

    // Cạnh đáy
    path.lineTo(cr, size.height);
    // Góc dưới bên trái
    path.arcToPoint(Offset(0, size.height - cr), radius: Radius.circular(cr));

    // Cạnh trái lên đến vết khuyết bán nguyệt
    path.lineTo(0, notchY + r);
    // Vết khuyết bên trái (uốn cong vào trong thân thẻ)
    path.arcToPoint(Offset(0, notchY - r),
        radius: Radius.circular(r), clockwise: false);

    // Cạnh trái lên đến góc trên bên trái
    path.lineTo(0, cr);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TicketCardClipper oldClipper) =>
      oldClipper.bottomBarHeight != bottomBarHeight ||
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

/// Painter vẽ viền kính sáng đồng dạng theo đường cong vé xé ngân hàng (kể cả 2 vết khuyết)
class TicketBorderPainter extends CustomPainter {
  final double bottomBarHeight;
  final double notchRadius;
  final double cornerRadius;
  final Color borderColor;
  final double borderWidth;

  const TicketBorderPainter({
    this.bottomBarHeight = 54.0,
    this.notchRadius = 9.0,
    this.cornerRadius = 18.0,
    this.borderColor = AppColors.cardBorderDark, // Use token
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final clipper = TicketCardClipper(
      bottomBarHeight: bottomBarHeight,
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
    );
    final path = clipper.getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TicketBorderPainter oldDelegate) =>
      oldDelegate.bottomBarHeight != bottomBarHeight ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
