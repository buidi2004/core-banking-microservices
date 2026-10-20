import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final PageController _cardPageCtrl = PageController(viewportFraction: 0.92);
  int _currentCardIdx = 0;

  bool _isLocked = false;
  bool _showDetails = false;
  bool _onlinePayment = true;
  bool _intlPayment = true;
  bool _atmWithdraw = true;
  String _cardHolderName = 'CHỦ THẺ SEN HỒNG';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileRemoteDataSource().getMe();
      final name = profile['fullName'] as String?;
      if (name != null && name.isNotEmpty && mounted) {
        setState(() {
          _cardHolderName = name.toUpperCase();
          for (final card in _cards) {
            card['holder'] = _cardHolderName;
          }
        });
      }

      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          for (final card in _cards) {
            if (card['type'] == 'debit') {
              card['available'] = wallet.balance;
            }
          }
        });
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _cards = [
    {
      'type': 'credit',
      'title': 'SEN HỒNG VISA SIGNATURE',
      'tier': 'THẺ TÍN DỤNG QUỐC TẾ',
      'number': '4288 9900 8899 6688',
      'maskedNumber': '•••• •••• •••• 6688',
      'holder': 'CHỦ THẺ SEN HỒNG',
      'expiry': '12/29',
      'cvv': '889',
      'limit': 150000000.0,
      'available': 112500000.0,
      'colorScheme': 'platinum',
      'useAsset': true,
    },
    {
      'type': 'debit',
      'title': 'SEN HỒNG NAPAS CHIP',
      'tier': 'THẺ GHI NỢ NỘI ĐỊA',
      'number': '9704 2200 6868 9999',
      'maskedNumber': '•••• •••• •••• 9999',
      'holder': 'CHỦ THẺ SEN HỒNG',
      'expiry': '08/30',
      'cvv': '•••',
      'limit': 100000000.0,
      'available': 12580000.0,
      'colorScheme': 'napas',
      'useAsset': false,
    },
    {
      'type': 'virtual',
      'title': 'SEN HỒNG VIRTUAL ECARD',
      'tier': 'THẺ ẢO THANH TOÁN ONLINE',
      'number': '4791 0088 7766 1234',
      'maskedNumber': '•••• •••• •••• 1234',
      'holder': 'CHỦ THẺ SEN HỒNG',
      'expiry': '05/28',
      'cvv': '452',
      'limit': 50000000.0,
      'available': 50000000.0,
      'colorScheme': 'virtual',
      'useAsset': false,
    },
  ];

  @override
  void dispose() {
    _cardPageCtrl.dispose();
    super.dispose();
  }

  void _showPhysicalCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Đăng Ký Phát Hành Thẻ Vật Lý',
                    style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimaryLight)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Thẻ vật lý công nghệ dập nổi cao cấp tích hợp chip vi mạch EMV contactless sẽ được chuyển phát nhanh miễn phí tới địa chỉ của bạn.',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_fill, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Địa chỉ nhận thẻ: P. Hàng Bạc, Q. Hoàn Kiếm, Hà Nội (Địa chỉ thường trú CCCD)',
                          style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock_fill, color: AppColors.accentGold, size: 20),
                      SizedBox(width: 10),
                      Text('Thời gian giao dự kiến: 3 - 5 ngày làm việc', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.gift_fill, color: AppColors.emeraldGreen, size: 20),
                      SizedBox(width: 10),
                      Text('Phí phát hành & Giao hàng: MIỄN PHÍ 100%', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.emeraldGreen,
                    content: Text('Đăng ký phát hành thẻ vật lý thành công! Mã đơn vận: #SHB-CARD-8899'),
                  ),
                );
              },
              child: const Text('Xác nhận đăng ký phát hành'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCard = _cards[_currentCardIdx];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Thẻ Sen Hồng'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => context.push('/payment-methods'),
            icon: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
            tooltip: 'Thêm phương thức thanh toán',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD CAROUSEL (VUỐT CHUYỂN ĐỔI GIỮA CÁC THẺ)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _cardPageCtrl,
                  itemCount: _cards.length,
                  onPageChanged: (idx) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentCardIdx = idx);
                  },
                  itemBuilder: (context, idx) {
                    final card = _cards[idx];
                    return AnimatedBuilder(
                      animation: _cardPageCtrl,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_cardPageCtrl.position.haveDimensions) {
                          value = (_cardPageCtrl.page ?? _currentCardIdx.toDouble()) - idx;
                        } else {
                          value = (_currentCardIdx - idx).toDouble();
                        }
                        final scale = (1.0 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                        final opacity = (1.0 - (value.abs() * 0.35)).clamp(0.65, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildCardItem(card),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Page Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_cards.length, (idx) {
                  final isSelected = idx == _currentCardIdx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.bottomBarCyan : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Card Limit Status Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCard['type'] == 'credit' ? 'Hạn mức khả dụng' : 'Số dư tài khoản thẻ',
                                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.formatVND(activeCard['available'] as double),
                                  style: AppTypography.titleLarge(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Tổng hạn mức:\n${CurrencyFormatter.formatVND(activeCard['limit'] as double)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. QUICK SECURITY SWITCH CHIPS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildQuickToggleChip(
                      icon: CupertinoIcons.cart_fill,
                      label: 'Online',
                      isActive: _onlinePayment,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _onlinePayment = !_onlinePayment);
                        _showToggleFeedback('Thanh toán trực tuyến E-Commerce', _onlinePayment);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickToggleChip(
                      icon: CupertinoIcons.globe,
                      label: 'Quốc tế',
                      isActive: _intlPayment,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _intlPayment = !_intlPayment);
                        _showToggleFeedback('Chi tiêu quốc tế POS/Online', _intlPayment);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickToggleChip(
                      icon: CupertinoIcons.arrow_down_circle_fill,
                      label: 'Rút ATM',
                      isActive: _atmWithdraw,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _atmWithdraw = !_atmWithdraw);
                        _showToggleFeedback('Rút tiền mặt ATM', _atmWithdraw);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. SPECIAL CASHBACK PROMOTION BANNER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.balanceCardGradient.colors[0], AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.bottomBarCyan.withOpacity(0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bottomBarGlow.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.sparkles, color: AppColors.accentGold, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ĐẶC QUYỀN THẺ SEN HỒNG',
                              style: AppTypography.titleSmall(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hoàn 5% chi tiêu ăn uống & du lịch. Tặng bảo hiểm du lịch toàn cầu tới 10.5 tỷ đồng.',
                              style: AppTypography.bodySmall(color: Colors.white70).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. MANAGEMENT OPTIONS LIST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quản lý bảo mật & Tính năng thẻ', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCardOption(
                      icon: _showDetails ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                      title: 'Xem số thẻ & mã bảo mật CVV',
                      subtitle: 'Hiển thị đầy đủ thông tin để thanh toán online',
                      trailing: Switch.adaptive(
                        value: _showDetails,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _showDetails = val);
                          if (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 2),
                                backgroundColor: AppColors.warningText,
                                content: Text('Cảnh báo: Tuyệt đối không chia sẻ mã CVV với bất kỳ ai, kể cả nhân viên ngân hàng.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    _buildCardOption(
                      icon: _isLocked ? CupertinoIcons.lock_open_fill : CupertinoIcons.lock_fill,
                      title: _isLocked ? 'Mở khóa thẻ' : 'Khóa thẻ tạm thời khẩn cấp',
                      subtitle: _isLocked ? 'Thẻ đang bị tạm khóa giao dịch' : 'Bảo vệ an toàn khi nghi ngờ lộ thông tin',
                      trailing: Switch.adaptive(
                        value: _isLocked,
                        activeTrackColor: AppColors.error,
                        onChanged: (val) => _confirmToggleLockCard(val),
                      ),
                    ),
                    _buildCardOption(
                      icon: CupertinoIcons.creditcard,
                      title: 'Phát hành thẻ vật lý dập nổi',
                      subtitle: 'Chuyển phát nhanh thẻ dập nổi tận nhà miễn phí',
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      onTap: _showPhysicalCardModal,
                    ),
                    _buildCardOption(
                      icon: CupertinoIcons.lock_shield_fill,
                      title: 'Đổi mã PIN thẻ ATM',
                      subtitle: 'Đổi mã PIN 6 số rút tiền tại cây ATM',
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      onTap: () => context.push('/auth/set-pin'),
                    ),
                    _buildCardOption(
                      icon: CupertinoIcons.slider_horizontal_3,
                      title: 'Cài đặt hạn mức thanh toán',
                      subtitle: 'Hạn mức chi tiêu trực tuyến mỗi ngày theo eKYC',
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      onTap: () => context.push('/profile/kyc-level'),
                    ),
                    _buildCardOption(
                      icon: CupertinoIcons.creditcard_fill,
                      title: 'Phương thức thanh toán & Nguồn tiền',
                      subtitle: 'Liên kết thẻ Visa, Mastercard, JCB quốc tế',
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      onTap: () => context.push('/payment-methods'),
                    ),
                    _buildCardOption(
                      icon: CupertinoIcons.building_2_fill,
                      title: 'Tài khoản ngân hàng liên kết',
                      subtitle: 'Quản lý tài khoản nạp/rút ngân hàng nội địa',
                      trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      onTap: () => context.push('/bank-cards'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    final isLocked = _isLocked;
    final useAsset = card['useAsset'] as bool;
    final displayNum = _showDetails ? card['number'] as String : card['maskedNumber'] as String;
    final displayExpiry = _showDetails ? card['expiry'] as String : '••/••';
    final displayCvv = _showDetails ? card['cvv'] as String : '•••';

    return GlassCard(
      quality: GlassQuality.standard,
      settings: const LiquidGlassSettings(specularSharpness: GlassSpecularSharpness.medium),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bottomBarCyan.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.bottomBarGlow.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: Ảnh thẻ thực tế hoặc Gradient cao cấp
              if (useAsset)
                Image.asset(
                  'assets/images/banking_card.png',
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: card['colorScheme'] == 'napas'
                          ? [AppColors.balanceCardGradient.colors[0], AppColors.primaryDark, AppColors.primary]
                          : [AppColors.textPrimaryLight, AppColors.cardDark, AppColors.softPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

              // Gradient Overlay bảo vệ độ tương phản chữ
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Card Information Layer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row 1: Brand & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset('assets/icons/senbank_lotus_isolated.png', width: 22, height: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  card['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isLocked ? AppColors.error : AppColors.emeraldGreen).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (isLocked ? AppColors.error : AppColors.emeraldGreen).withOpacity(0.6)),
                          ),
                          child: Text(
                            isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                            style: TextStyle(
                              color: isLocked ? AppColors.error : AppColors.emeraldGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Row 2: Chip EMV & Contactless
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentGold, AppColors.warningText],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Icon(CupertinoIcons.square_grid_2x2_fill, color: Colors.black45, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(CupertinoIcons.radiowaves_right, color: Colors.white70, size: 20),
                        const Spacer(),
                        Text(
                          card['tier'] as String,
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    // Row 3: Card Number & Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displayNum,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w700,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                card['holder'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Text('HSD: $displayExpiry', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(width: 10),
                                Text('CVV: $displayCvv', style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
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
  }

  Widget _buildQuickToggleChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? AppColors.primary : AppColors.textMutedLight, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        quality: GlassQuality.minimal,
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            title: Text(title, style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
            subtitle: Text(subtitle, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
            trailing: trailing ?? const Icon(CupertinoIcons.chevron_forward, size: 18, color: AppColors.textMutedLight),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmToggleLockCard(bool willLock) async {
    HapticFeedback.mediumImpact();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              willLock ? CupertinoIcons.lock_shield_fill : CupertinoIcons.lock_open_fill,
              color: willLock ? AppColors.error : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                willLock ? 'Khóa Thẻ Tạm Thời' : 'Mở Khóa Thẻ',
                style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
        content: Text(
          willLock
              ? 'Sau khi tạm khóa, toàn bộ các giao dịch thanh toán trực tuyến, quẹt thẻ POS và rút tiền ATM sẽ bị từ chối ngay lập tức để bảo vệ tài khoản của bạn.'
              : 'Bạn có chắc chắn muốn mở khóa lại thẻ này? Thẻ sẽ sẵn sàng cho tất cả các giao dịch thanh toán và rút tiền.',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willLock ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willLock ? 'Xác nhận khóa' : 'Xác nhận mở'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _isLocked = willLock);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: willLock ? AppColors.error : AppColors.emeraldGreen,
          content: Text(
            willLock
                ? 'Đã tạm khóa thẻ an toàn thành công!'
                : 'Đã mở khóa thẻ thành công! Thẻ đã sẵn sàng giao dịch.',
          ),
        ),
      );
    }
  }

  void _showToggleFeedback(String feature, bool status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: status ? AppColors.emeraldGreen : AppColors.textSecondaryLight,
        content: Text('$feature: ${status ? "ĐÃ BẬT" : "ĐÃ TẮT"}'),
      ),
    );
  }
}
