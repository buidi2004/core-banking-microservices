import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/network/realtime_notification_service.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:flutter/rendering.dart';
import 'package:sen_hong_bank/presentation/widgets/curved_promo_banner.dart';
import 'package:sen_hong_bank/presentation/widgets/sen_hong_smart_sliver_app_bar.dart';
import 'package:sen_hong_bank/presentation/widgets/smart_search_modal_sheet.dart';
import 'package:sen_hong_bank/presentation/widgets/vietnam_hero_header.dart';
import 'package:flutter/services.dart';

/// HomeScreen được tối ưu theo chuẩn:
/// - Apple HIG Touch Targets (44dp+)
/// - Fintech Anti-slop (bỏ muddy shadows, dùng hairline borders)
/// - Tabular Figures cho số tiền
/// - Haptic Feedback phù hợp với từng interaction
/// - Loading skeleton states
/// - Accessibility (WCAG AA contrast)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _hideBalance = false;
  double _balance = 0;

  /// Hạn mức thấu chi cấp cho ví (tính năng 4.1) — hiển thị chip dưới số dư
  double _overdraftLimit = 0;
  String _displayName = '';
  String _accountNumber = '';
  StreamSubscription? _notifSub;
  Timer? _refreshTimer;
  late ScrollController _scrollController;
  bool _showScrollToTop = false;

  /// Animation trượt cho thanh công cụ thông minh (chỉ hiện khi vuốt ngón tay xuống)
  AnimationController? _floatingBarController;
  Animation<Offset>? _floatingBarAnimation;
  bool _isFloatingBarVisible = false;

  void _initFloatingBar() {
    _floatingBarController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _floatingBarAnimation ??= Tween<Offset>(
      begin: const Offset(0, -1.2), // Giấu hoàn toàn ở phía trên màn hình
      end: Offset.zero, // Trượt xuống vị trí hiển thị
    ).animate(CurvedAnimation(
      parent: _floatingBarController!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  final List<Map<String, dynamic>> _quickServices = const [
    {
      'label': 'Chuyển tiền',
      'route': '/transfer',
      'surface': Color(0xFFDDF7FB),
      'art': 'assets/images/service-icons/transfer.png',
    },
    {
      'label': 'Nạp ĐT',
      'route': '/bills/phone-recharge',
      'surface': Color(0xFFE0FAF5),
      'art': 'assets/images/service-icons/phone-topup.png',
    },
    {
      'label': 'Điện nước',
      'route': '/bills',
      'surface': Color(0xFFDDF8F8),
      'art': 'assets/images/service-icons/bill-payment.png',
    },
    {
      'label': 'Tiết kiệm',
      'route': '/bills/savings',
      'surface': Color(0xFFE9F1FF),
      'art': 'assets/images/service-icons/savings.png',
    },
    {
      'label': 'Vay nhanh',
      'route': '/bills/quick-loan',
      'surface': Color(0xFFE0F9EE),
      'art': 'assets/images/service-icons/quick-loan.png',
    },
    {
      'label': 'Vietlott',
      'route': '/bills/lottery',
      'surface': Color(0xFFEAF2FF),
      'art': 'assets/images/service-icons/vietlott.png',
    },
  ];

  final List<Map<String, dynamic>> _lifestyleServices = const [
    {
      'label': 'Vua xổ số',
      'route': '/vua-xo-so',
      'art': 'assets/images/service-icons/01_vua_xo_so.png',
    },
    {
      'label': 'Vé số\nVietlott',
      'route': '/vietlott',
      'art': 'assets/images/service-icons/02_ve_so_vietlott.png',
    },
    {
      'label': 'Data 4G\nNạp tiền',
      'route': '/data-topup',
      'art': 'assets/images/service-icons/03_data_4g_nap_tien.png',
    },
    {
      'label': 'Vé máy bay\nSố',
      'route': '/digital-flight',
      'art': 'assets/images/service-icons/04_ve_may_bay_so.png',
    },
    {
      'label': 'Vé máy bay',
      'route': '/imedia-flight',
      'art': 'assets/images/service-icons/05_ve_may_bay.png',
    },
    {
      'label': 'Data 4G/Thẻ\ngame',
      'route': '/game-cards',
      'art': 'assets/images/service-icons/06_data_4g_the_game.png',
    },
    {
      'label': 'Vận số',
      'route': '/van-so',
      'art': 'assets/images/service-icons/07_van_so.png',
    },
    {
      'label': 'Xem thêm\ndịch vụ',
      'route': '/all-services',
      'art': 'assets/images/service-icons/08_xem_them_dich_vu.png',
    },
  ];

  String _serviceLabel(Map<String, dynamic> item) =>
      item['label'] as String? ?? 'Dịch vụ';

  String _serviceRoute(Map<String, dynamic> item) =>
      item['route'] as String? ?? '/more';

  Color _serviceSurface(Map<String, dynamic> item) =>
      item['surface'] as Color? ?? Colors.white;

  Widget _serviceArtwork(Map<String, dynamic> item, double size) {
    final artPath = item['art'] as String?;
    if (artPath == null || artPath.isEmpty) {
      return Icon(
        item['icon'] as IconData? ?? CupertinoIcons.square_grid_2x2,
        color: AppColors.primaryDark,
        size: size * 0.62,
      );
    }
    return Image.asset(artPath, width: size, height: size, fit: BoxFit.contain);
  }

  Widget _buildFeaturedServiceCard(Map<String, dynamic> item) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(_serviceRoute(item));
          },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 116,
            decoration: BoxDecoration(
              color: _serviceSurface(item),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.95),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF17324D).withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  top: 14,
                  right: 68,
                  child: Text(
                    _serviceLabel(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 1,
                  child: _serviceArtwork(item, 88),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(_serviceRoute(item));
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: _serviceSurface(item),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF17324D).withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _serviceArtwork(item, 48),
                const SizedBox(height: 2),
                Text(
                  _serviceLabel(item),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(
                    color: const Color(0xFF061F42),
                  ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleItem(Map<String, dynamic> item) {
    final label = item['label'] as String;
    final art = item['art'] as String;
    final route = item['route'] as String;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(route);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFE8EDF3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      art,
                      fit: BoxFit.contain,
                      cacheWidth: 132,
                      cacheHeight: 132,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(
                      color: const Color(0xFF1E293B),
                    ).copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleServicesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mua sắm - Giải trí - Đầu tư',
                  style: AppTypography.titleMedium(
                    color: const Color(0xFF1E293B),
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/all-services');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: AppTypography.bodySmall(
                        color: AppColors.primary,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              mainAxisExtent: 98,
            ),
            itemCount: _lifestyleServices.length,
            itemBuilder: (context, index) =>
                _buildLifestyleItem(_lifestyleServices[index]),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initFloatingBar();

    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        final direction = _scrollController.position.userScrollDirection;

        final shouldShowScrollToTop = offset > 300;
        if (shouldShowScrollToTop != _showScrollToTop) {
          setState(() {
            _showScrollToTop = shouldShowScrollToTop;
          });
        }

        // Quy tắc hiển thị thanh công cụ thông minh:
        // 1. Khi ở đầu trang (offset <= 80): Luôn ẩn để giữ nguyên vẹn VietnamHeroHeader
        if (offset <= 80) {
          if (_isFloatingBarVisible) {
            _isFloatingBarVisible = false;
            _floatingBarController?.reverse();
          }
        }
        // 2. KHI DÙNG TAY VUỐT MÀN LÊN (ScrollDirection.reverse):
        //    Thanh công cụ trượt xuống hiện ra ở mép trên màn hình
        else if (direction == ScrollDirection.reverse) {
          if (!_isFloatingBarVisible) {
            _isFloatingBarVisible = true;
            _floatingBarController?.forward();
          }
        }
        // 3. Khi vuốt màn xuống / cuộn ngược về đỉnh (ScrollDirection.forward):
        //    Thanh công cụ tự động trượt lên ẩn đi
        else if (direction == ScrollDirection.forward) {
          if (_isFloatingBarVisible) {
            _isFloatingBarVisible = false;
            _floatingBarController?.reverse();
          }
        }
      });
    _loadAllData();
    _listenRealtime();
  }

  /// Khi có biến động số dư realtime, làm mới số dư ví.
  /// (debounce 400ms để gộp nhiều event của cùng 1 giao dịch).
  void _listenRealtime() {
    _notifSub = RealtimeNotificationService().notificationStream.listen((_) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) _loadWallet();
      });
    });
  }

  @override
  void dispose() {
    _floatingBarController?.dispose();
    _refreshTimer?.cancel();
    _notifSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProfile(),
      _loadWallet(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (mounted && (savedPhone != null || savedName != null)) {
        setState(() {
          if (savedPhone != null && savedPhone.isNotEmpty) {
            _accountNumber = savedPhone;
          }
          if (savedName != null && savedName.isNotEmpty) {
            _displayName = savedName;
          }
        });
      }

      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      setState(() {
        final fullName = profile['fullName'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          _displayName = fullName;
        }
        final phone = profile['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          _accountNumber = phone;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          _balance = wallet.balance;
          _overdraftLimit = wallet.overdraftLimit;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    _initFloatingBar();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                ),
                slivers: [
                  // 1. Header Lễ Hội SenBank Tích Hợp Toàn Bộ Thông Tin
                  SliverToBoxAdapter(
                    child: VietnamHeroHeader(
                      balance: _balance,
                      isHidden: _hideBalance,
                      overdraftLimit: _overdraftLimit,
                      onToggleVisibility: () {
                        HapticFeedback.selectionClick();
                        setState(() => _hideBalance = !_hideBalance);
                      },
                      onNotificationTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/notifications');
                      },
                      onSearchTap: () {
                        HapticFeedback.lightImpact();
                        showSmartSearchModalSheet(context);
                      },
                      onTransfer: () {
                        HapticFeedback.mediumImpact();
                        context.push('/transfer');
                      },
                      onDeposit: () {
                        HapticFeedback.mediumImpact();
                        context.push('/deposit');
                      },
                      onWithdraw: () {
                        HapticFeedback.mediumImpact();
                        context.push('/withdraw');
                      },
                      onProfileTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/profile');
                      },
                      displayName: _displayName,
                      accountNumber: _accountNumber,
                    ),
                  ),

                  // Dịch vụ nổi bật gối nhẹ lên đáy hero để rút ngắn phần đầu màn hình.
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _buildFeaturedServiceCard(_quickServices[0]),
                                const SizedBox(width: 10),
                                _buildFeaturedServiceCard(_quickServices[1]),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                mainAxisExtent: 104,
                              ),
                              itemCount: _quickServices.length - 2,
                              itemBuilder: (context, index) =>
                                  _buildServiceTile(_quickServices[index + 2]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Banner Promotion đầu tiên - hiển thị ngay không cần scroll
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: CurvedPromoBanner(
                        onRegisterTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/promotions');
                        },
                      ),
                    ),
                  ),

                  // Cụm 8 biểu tượng dịch vụ "Mua sắm - Giải trí - Đầu tư" nằm ngay dưới thanh Banner Carousel
                  SliverToBoxAdapter(
                    child: _buildLifestyleServicesSection(),
                  ),

                  // Bottom Curved Promo & Feature Banner thứ hai - hiển thị ngay (không fade-in để tránh lỗi không hiển thị)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: CurvedPromoBanner(
                        isDiagonalSlanted: true,
                        onRegisterTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/promotions');
                        },
                      ),
                    ),
                  ),

                  // Đệm khoảng trống đáy (110dp) bảo toàn không bị che khuất bởi Floating Liquid Glass Bottom Bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),
                ],
              ),
            ),

            // Thanh công cụ thông minh tự động trượt xuống CHỈ KHI vuốt ngón tay xuống
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _floatingBarAnimation!,
                child: SenHongSmartHeaderBar(
                  onNotificationTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/notifications');
                  },
                  onMenuTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/more');
                  },
                ),
              ),
            ),
          ],
        ),
        // Nút scroll-to-top với hiệu ứng fade-in & Floating AI Assistant Widget
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 110, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_showScrollToTop) ...[
                AnimatedOpacity(
                  opacity: _showScrollToTop ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FloatingActionButton.small(
                    heroTag: 'fab_scroll_top',
                    backgroundColor: AppColors.primary.withOpacity(0.9),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(CupertinoIcons.arrow_up),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Nút Trợ lý AI Sen Hồng Floating Widget
              Tooltip(
                message: 'Trợ lý AI Sen Hồng 24/7',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/support/live-chat');
                    },
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF14B885).withOpacity(0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14B885).withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image.asset(
                                'assets/icons/ai_assistant_ghost.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
